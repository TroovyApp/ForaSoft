'use strict';

const validationError = require('../apiError').validationError;

module.exports = (body) => {
    if (!body.entityId) {
        return validationError('Entity id is required');
    }
    if (!body.entityType) {
        return validationError('Entity type is required');
    }
};
