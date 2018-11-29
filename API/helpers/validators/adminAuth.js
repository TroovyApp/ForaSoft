'use strict';

const validationError = require('../apiError').validationError;

module.exports = (body) => {
    if (!body.email)
        return validationError('Email is required');
    if (!body.password)
        return validationError('Password is required');
    return null;
};
