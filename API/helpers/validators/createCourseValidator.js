'use strict';

const validateSessionTime = require('../../domain/sessionsUtils').validateSessionTime;

const validationError = require('../apiError').validationError;


module.exports = function* (user, body) {
    const error = {};
    if (!body.title)
        error.title = 'Title is required';
    if (!body.description)
        error.description = 'Description is required';
    if (body.sessions) {
        const isTimeInvalid = yield body.sessions.map(sessionData => {
            const {duration, startAt} = sessionData;
            if (!duration || !startAt)
                return false;
            return validateSessionTime(user, startAt, duration);
        });
        body.sessions.forEach((sessionData, index) => {
            const sessionError = {};
            if (!sessionData.title)
                sessionError.title = 'Title is required';
            if (!sessionData.title)
                sessionError.description = 'Description is required';
            if (!sessionData.startAt)
                sessionError.startAt = 'Session\'s start time is required';
            if (!sessionData.duration)
                sessionError.duration = 'Session\'s duration is required';
            if (Boolean(isTimeInvalid[index]))
                sessionError.startAt = 'Session time is in past or cross with your other sessions';
            if (Object.keys(sessionError).length === 0)
                return;
            if (!error.sessions) {
                error.sessions = [];
            }
            error.sessions[index] = sessionError;
        });
        normalizeSessionError(error.sessions);
    }
    if (!body.currency)
        error.currency = 'Currency is required';
    if (body.currency !== user.currency && user.currency) {
        error.currency = 'You cannot change currency of courses'
    }

    if (Object.keys(error).length > 0)
        return validationError(error);
};

const normalizeSessionError = (errors) => {
    if (errors) {
        for (let i = 0; i < errors.length; i++) {
            if (!errors[i])
                errors[i] = {};
        }
    }
};