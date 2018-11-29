const modes = {
    HIDDEN: 'hidden',
    SHOW: 'show'
};

class ContentListener {
    constructor() {
        this.mode = modes.HIDDEN;
        this.$content = $('.course-content');
        this.$header = $('.course-header');

        this.init();
    }

    init() {
        this._initCourseContent();
        window.addEventListener('resize', e => {
            this._initCourseContent(true);
        });

        // this.$content.swipe({
        //     swipeUp: event => {
        //         if (this.mode === modes.SHOW)
        //             return;
        //         this.mode = modes.SHOW;
        //         this._initCourseContent();
        //     },
        //     swipeDown: event => {
        //         if (this.mode === modes.HIDDEN)
        //             return;
        //         this.mode = modes.HIDDEN;
        //         this._initCourseContent();
        //     }
        // });

        // $('.arrow').click(() => {
        //     this.mode = this.mode === modes.HIDDEN ? modes.SHOW : modes.HIDDEN;
        //     this._initCourseContent();
        // });
    }

    _initCourseContent(isForce) {
        if (isForce)
            this.$content.addClass('notransition');
        this.$content.removeClass('big');
        this.$content.removeAttr('style');

        const headerHeight = this.$header.height();
        const contentHeight = this.$content.height();
        const containerHeight = $('.container').height();
        if (containerHeight - headerHeight <= contentHeight) {
            this.$content.addClass('big');
        }

        this.$content.removeClass('notransition');
    }
}

export default new ContentListener();
