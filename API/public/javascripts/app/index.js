import showCourcePrice from './helpers/showCourcePrice';
import StripePaymentApp from './StripePaymentApp';

let paymentApp = null;

$(document).ready(function () {
    showCourcePrice();
    paymentApp = new StripePaymentApp();
    $('.js-subscribe-btn').off('click').click(onSubscribeClick);
    /* sticky for video player */
    $('.ui.sticky')
        .sticky({
            offset: 68,
            context: '#js-subscribe-context'
        });

});

function onSubscribeClick(e) {
    e.preventDefault();
    e.stopPropagation();
    paymentApp.run();
}
