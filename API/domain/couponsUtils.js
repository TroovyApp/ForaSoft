const config = require('../config');
const stripe = require('stripe')(config.stripeSecretKey);
const notFoundError = require('../helpers/apiError').notFoundError;

const checkCoupon = function* (name) {
    if (!name) {
        return;
    }

    const {percent_off, valid} = yield fetchCouponPercents(name);

    if (!percent_off || !valid) {
        throw notFoundError(404, `No such coupon: ${name}`);
    }

    return {percent_off};
};

const fetchCouponPercents = function* (name) {
    try {
        const coupon = yield stripe.coupons.retrieve(name);

        const {percent_off_precise, valid} = coupon;

        return {percent_off: percent_off_precise, valid};
    } catch (err) {
        throw notFoundError(404, err.message);
    }
};

module.exports = {
    checkCoupon,
};