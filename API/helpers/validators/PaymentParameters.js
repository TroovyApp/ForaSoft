'use strict';

const validationError = require('../apiError').validationError;

const paymentFromBalanceParameters = function* (user, body) {
    const error = {};
    if (!body.price)
        error.price = 'price is required';

    if (Object.keys(error).length > 0)
        return validationError(error);
};

const paymentFromCardParameters = function* (user, body) {
    const error = {};
    if (!(body.stripeToken || body.coupon))
        error.stripeToken = 'stripeToken is required';

    if (Object.keys(error).length > 0)
        return validationError(error);
};

const paymentFromMixedParameters = function* (user, body) {
    const error = {};
    if (!body.price)
        error.price = 'price is required';
    if (!body.amountFromCard)
        error.amountFromCard = 'amountFromCard is required';
    if (!body.stripeToken)
        error.stripeToken = 'stripeToken is required';

    if (Object.keys(error).length > 0)
        return validationError(error);
};

module.exports = {
    paymentFromBalanceParameters,
    paymentFromCardParameters,
    paymentFromMixedParameters
};
