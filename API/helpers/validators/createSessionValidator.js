'use strict';

const validationError = require('../apiError').validationError;

module.exports = (body) => {
    if (!body.title) {
        return validationError('Title is required');
    }
    if (!body.description) {
        return validationError('Description is required');
    }
    if (!body.startAt) {
        return validationError('Session\'s start time is required');
    }
    if (!body.duration) {
        return validationError('Session\'s duration is required');
    }
    if (!body.courseId) {
        return validationError('Workshop\'s id is required');
    }
};
