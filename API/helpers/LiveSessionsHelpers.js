'use strict';

const moment = require('moment');

const LiveSessionRepository = require('../repositories/LiveSessionRepository');
const internalRoute = require('../sockets/routes/InternalRoute');

const {forceFinishedSession} = require('../helpers/errors/sessionErrors');

const startSessionHelper = function*(user, sessionId) {
    const error = yield LiveSessionRepository.isCanStart(user, sessionId);
    if (error)
        throw error;

    const liveSession = yield LiveSessionRepository.start(sessionId);
    internalRoute.emit('internal:emitToAllInRoom', sessionId, 'session:started', {
        sessionInfo: liveSession.session.toDTO(),
        currentServerTime: moment().utc().unix(),
        userList: liveSession.participants,
        status: liveSession.status
    });
};

const finishSessionHelper = function*(user, sessionId, asAdmin = false) {
    const error = yield LiveSessionRepository.isCanFinish(user, sessionId);
    if (error && !asAdmin)
        throw error;

    if (asAdmin) {
        internalRoute.emit('internal:emitToUser', user.id, 'session:forceLogout', forceFinishedSession("Your session was finished by Admin"));
    }

    const liveSession = yield LiveSessionRepository.finish(sessionId);
    internalRoute.emit('internal:emitToAllInRoom', sessionId, 'session:finished', {
        sessionInfo: liveSession.session.toDTO(),
        currentServerTime: moment().utc().unix(),
        userList: liveSession.participants,
        status: liveSession.status
    });
};

module.exports = {
    startSessionHelper,
    finishSessionHelper
};
