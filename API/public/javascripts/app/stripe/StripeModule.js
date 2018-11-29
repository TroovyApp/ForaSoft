import uiConnector from '../ui/UIConnector';
import makeRequest from '../ApiClient';
import hasError from '../helpers/isError';

export default class StripeModule {
    constructor() {
        this.stripe = Stripe(config.STRIPE_KEY);
        this.executePromise = null;
    }

    pay() {
        return new Promise((res, rej) => {
            this.executePromise = res;
            uiConnector.showStripeCardPopup(this.stripe, this._sendPayToken.bind(this), this._checkCoupon.bind(this));
        });
    }

    async _checkCoupon(coupon) {
        const response = await makeRequest({
            method: 'post',
            path: '/payments/coupon',
            data: {
                coupon,
            }
        });
        if (hasError(response) || !response.data.result) {
            uiConnector.setDiscount(0);
            return;
        }

        const {data: {result: {percent_off}}} = response;

        uiConnector.setDiscount(percent_off);
    }

    async _sendPayToken(token, email, coupon) {
        const response = await makeRequest({
            method: 'post',
            path: `/payments/card/course/${config.courseId}`,
            data: {
                stripeToken: token ? token.id : null,
                price: config.coursePrice,
                coupon: coupon
            }
        });
        if (hasError(response))
            return;

        await makeRequest({
            method: 'post',
            path: `/payments/receipt/${config.courseId}`,
            data: {email}
        });

        this.executePromise();
    }

}