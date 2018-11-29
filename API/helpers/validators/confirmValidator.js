'use strict';

const validationError = require('../apiError').validationError;

module.exports = (body) => {
    if (!body.appGeneratedToken)
        return validationError('App generated token is required');
    if (!body.confirmationCode)
        return validationError('Confirmation code is required');
    return null;
};
