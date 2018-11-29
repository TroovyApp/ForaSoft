import AuthModule from './auth/AuthModule';
import StripeModule from './stripe/StripeModule';
import StorageHelper from './auth/StorageHelper';
import showCourcePrice from './helpers/showCourcePrice';

export default class StripePaymentApp {
    constructor() {
        this.auth = new AuthModule();
        this.auth.on('logout', this._changeButtonParameters.bind(this));
        this.stripe = new StripeModule();
        this._changeButtonParameters();
    }

    _changeButtonParameters(isForce = false) {
        const $subscribeButton = $('.js-subscribe-btn');
        if (!this.auth.isAuth()) {
            showCourcePrice();
            $subscribeButton.off('click').on('click', this.run.bind(this));
            return;
        }

        const user = StorageHelper.getUser();
        if (config.creator !== user.id && config.subscribers.indexOf(user.id) < 0 && !isForce)
            return false;

        $subscribeButton
            .text('Open workshop')
            .off('click')
            .on('click', this.redirectToWorkshop.bind(this));
        return true;
    }


    async run() {
        if (!this.auth.isAuth())
            await this.auth.authenticate();

        const isChanged = this._changeButtonParameters(false);
        if (isChanged)
            return $('#popupS-overlay').click();

        await this.stripe.pay();
        this._changeButtonParameters(true);
        this.redirectToWorkshop();
    }

    redirectToWorkshop() {
        window.location = 'https://itunes.apple.com/us/app/troovy/id1375971590';
    }
}
