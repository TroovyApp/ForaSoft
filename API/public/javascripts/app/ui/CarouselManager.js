import CarouselItem from './CarouselItem';

export default class CarouselManager {
    constructor() {
        this.items = [];
        $('.background').each((index, el) => {
            this.items.push(new CarouselItem(el, index, this.onVideoEnded.bind(this)));
        });

        this.currentStep = 0;
        this.baseOffset = window.innerWidth;
        this.loadLayout({withoutAnimation: true});
        window.addEventListener('resize', () => {
            this.loadLayout({withoutPlaying: true});
        });
    }

    loadLayout({withoutPlaying, withoutAnimation}) {
        if (this.items.length === 0)
            return;

        this.items.map((item, index) => {
            item.changeStyles(this.getStylesForItem(index), withoutAnimation || withoutPlaying);
        });
        if (!withoutPlaying)
            this.items[this.currentStep].play(this.onVideoEnded.bind(this));

    }

    getStylesForItem(itemIndex) {
        const absoluteIndex = itemIndex - this.currentStep;
        const offset = this.baseOffset * absoluteIndex;
        return {
            left: `${offset}px`
        };
    }

    onVideoEnded() {
        this.currentStep = this.currentStep + 1 < this.items.length ? this.currentStep + 1 : 0;
        if (this.currentStep === 0)
            this.items.forEach(item => {
                item.resetProgress();
            });
        requestAnimationFrame(() => {
            this.loadLayout({});
        });
    }

}