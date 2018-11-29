export default class CarouselItem {
    constructor(container, index, onVideoEnded) {
        this.childContainer = $(container);
        this.childVideo = this.childContainer.find('video')[0];
        this.addProgress(index);
        if (this.childVideo)
            this.initVideo(onVideoEnded);
    }

    addProgress(index) {
        const progressContainer = '<div class="progress-container"><div class="progress-value"></div></div>';
        $('.progress-wrapper').append(progressContainer);
        this.progress = $(`.progress-container:eq(${index})`);
    }

    initVideo(cb) {
        this.childVideo.addEventListener('ended', this.onVideoEnded.bind(this, cb));
        this.childVideo.addEventListener('timeupdate', this.onTimeUpdated.bind(this));
        $(this.childVideo).on('click', () => {
            this.childVideo.play();
            this.childVideo.muted = !this.childVideo.muted;
        });
    }

    play(onVideoEnded) {
        this.childContainer.removeClass('notransition');
        if (this.childContainer.attr('data-is-image')) {
            // console.log('play image');
            setTimeout(() => {
                this.onVideoEnded(onVideoEnded);
                // console.log('stop image');
            }, 3000);
            this.runProgress();
        } else {
            this.progress.find('.progress-value').removeClass('notransition');
            this.childVideo.currentTime = 0;
            this.childVideo.play();
            // console.log('play video');

        }
    }

    runProgress() {
        this.progress.find('.progress-value').addClass('notransition');
        this.progress.find('.progress-value').css({width: 0});
        this.progress.find('.progress-value').addClass('image-progress-animation');
        this.progress.find('.progress-value').removeClass('notransition');
        this.progress.find('.progress-value').css({width: '100%'});
    }

    resetProgress() {
        this.progress.find('.progress-value').addClass('notransition');
        this.progress.find('.progress-value').css({width: 0});
    }

    onVideoEnded(cb) {
        if (this.childVideo) {
            // console.log('stop video');
        }
        cb();
    }

    onTimeUpdated() {
        const {currentTime, duration} = this.childVideo;
        const progress = this.progress.width() * currentTime / duration;
        this.progress.find('.progress-value').css({width: `${progress}px`});
    }

    changeStyles(styles, withoutAnimation = false) {
        if (withoutAnimation)
            this.childContainer.addClass('notransition');

        this.childContainer.css(styles);
    }
}

