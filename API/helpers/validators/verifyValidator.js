'use strict';

const validationError = require('../apiError').validationError;

module.exports = (body) => {
    if (!body.dialCode && !body.phoneNumber)
        return validationError('Phone number and dial code is required');
    if (!body.dialCode)
        return validationError('Dial code is required');
    if (!body.phoneNumber)
        return validationError('Phone number is required');
    if (!body.appGeneratedToken)
        return validationError('App generated token is required');
    return null;
};

