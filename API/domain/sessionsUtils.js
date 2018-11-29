'use strict';

const moment = require('moment');

const internalRoute = require('../sockets/routes/InternalRoute');

const SessionRepository = require('../repositories/SessionRepository');
const LiveSessionRepository = require('../repositories/LiveSessionRepository');
const {startSessionHelper, finishSessionHelper} = require('../helpers/LiveSessionsHelpers');

const baseError = require('../helpers/apiError').baseError;
const validationError = require('../helpers/apiError').validationError;
const notFoundError = require('../helpers/apiError').notFoundError;
const constants = require('../constants/sessionConstants');

const validateObjectId = require('../helpers/validators/validateObjectId');
const parseQualities = require('../helpers/qualitiesParser');

const validateSessionTime = function*(user, startAt, duration, sessionId) {
    const isValid = yield SessionRepository.isSessionTimeValid(user, startAt, duration, sessionId);
    if (!isValid) {
        return validationError('Session time is in past or cross with your other sessions');
    }
    return null;
};

const createSession = function*(course, title, description, duration, startAt) {
    yield course.populate('creator').execPopulate();
    const validationError = yield validateSessionTime(course.creator, startAt, duration);
    if (validationError) {
        throw validationError;
    }
    const session = yield SessionRepository.createSession(course, title, description, duration, startAt);
    course.sessions.addToSet(session);
    yield course.save();
    return session;
};

const SESSION_FIELDS = ['title', 'description', 'duration', 'startAt'];

const editSession = function*(user, sessionId, body) {
    if (!validateObjectId(sessionId))
        throw validationError('Session id is not valid');

    const session = yield SessionRepository.findSession(sessionId, user);

    if (!session)
        throw notFoundError(404, 'Session is not found');

    const isCanEditSession = validateEditSessionTime(session);
    if (!isCanEditSession)
        throw validationError('You can not edit past sessions or which start less than 10 minutes');

    let {duration, startAt} = body;
    if (duration || startAt) {
        duration = Boolean(duration) ? duration : session.duration;
        startAt = Boolean(startAt) ? startAt : session.startAt;

        const validationError = yield validateSessionTime(user, startAt, duration, sessionId);
        if (validationError) {
            throw validationError;
        }
    }

    const sessionQualities = parseQualities(body, SESSION_FIELDS);
    if (sessionQualities.startAt) {
        sessionQualities.startAt = moment.unix(sessionQualities.startAt).valueOf();
    }
    return yield SessionRepository.editSession(sessionId, sessionQualities);
};

const validateEditSessionTime = function (session) {
    const currentTime = moment().utc().unix();
    const sessionTime = moment(session.startAt).utc().unix();
    return sessionTime - constants.SESSION_NOT_EDITING_TIME > currentTime;
};

const startSession = function*(user, sessionId) {
    yield startSessionHelper(user, sessionId);
};

const finishSession = function*(user, sessionId) {
    yield finishSessionHelper(user, sessionId);
};

const deleteSession = function*(user, sessionId) {
    const session = yield SessionRepository.findSession(sessionId, user);

    if (!session)
        throw notFoundError(404, 'Session is not found');

    const isCanEditSession = validateEditSessionTime(session);
    if (!isCanEditSession)
        throw validationError('You can not delete past sessions or which start less than 10 minutes');

    return yield SessionRepository.deleteSession(user, session.id);
};

const findSessionAttachments = function* (sessionId) {
    if (!validateObjectId(sessionId))
        throw validationError('Session id is not valid');

    const session = yield SessionRepository.findSession(sessionId);

    if (!session)
        throw notFoundError(404, 'Session is not found');

    return yield SessionRepository.findSessionAttachments(session);
};

module.exports = {
    validateSessionTime,
    createSession,
    editSession,
    startSession,
    finishSession,
    deleteSession,
    findSessionAttachments
};
