'use strict';

const validationError = require('../apiError').validationError;

const MINIMUM_PAYOUT_AMOUNT = require('../../constants/appConstants').MINIMUM_PAYOUT_AMOUNT;

module.exports = function*(user, body) {
    const error = {};
    if (!body.amountCredits)
        error.amountCredits = 'The amount should is required';
    if (!Number(body.amountCredits))
        error.amountCredits = 'The amount should be a Number';
    if (Number(body.amountCredits) < MINIMUM_PAYOUT_AMOUNT)
        error.amountCredits = `The amount should not be less than ${MINIMUM_PAYOUT_AMOUNT}`;
    if (!body.bankAccountNumber)
        error.bankAccountNumber = 'Credit card number is required';

    if (Object.keys(error).length > 0)
        return validationError(error);
};

