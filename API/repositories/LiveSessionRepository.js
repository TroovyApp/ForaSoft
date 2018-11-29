'use strict';

const moment = require('moment');

const LiveSessionModel = require('../schemas/LiveSessionSchema');
const SessionModel = require('../schemas/SessionsSchema');

const notFoundError = require('../helpers/apiError').notFoundError;
const validationError = require('../helpers/apiError').validationError;
const baseError = require('../helpers/apiError').baseError;

const fromMinutesToSeconds = require('../utils/fromMinutesToSeconds');
const ALLOWED_TIME = require('../constants/sessionConstants').SESSION_NOT_EDITING_TIME;
const liveSessionStatus = require('../constants/sessionConstants').liveSessionStatus;

class LiveSessionRepository {
    static* isCanJoin(user, sessionId) {
        const session = yield SessionModel.findOne({_id: sessionId}).populate('course').exec();
        if (!session) {
            return notFoundError(404, 'Session is not found');
        }
        if (!LiveSessionRepository._isSubscribedToCourse(user, session.course)
            && !LiveSessionRepository._isOwner(user, session.course)) {
            return validationError('You are not subscribed to this workshop');
        }

        yield session.course.populate('creator').execPopulate();
        if (session.course.creator.isDisabled)
            return validationError('Sorry, the workshop is temporarily unavailable');

        const currentTime = moment().utc().unix();
        const sessionEndTime = moment(session.startAt).utc().unix() + fromMinutesToSeconds(session.duration);
        if (currentTime > sessionEndTime) {
            return validationError('Session is expired');
        }
        const sessionStartTime = moment(session.startAt).utc().unix() - ALLOWED_TIME;
        if (currentTime < sessionStartTime) {
            return validationError('Session is not started');
        }
        const liveSession = yield LiveSessionRepository._getOrCreate(sessionId);
        if (liveSession.status === liveSessionStatus.FINISHED) {
            const error = baseError(503, 'Session is finished');
            error.session = {
                sessionInfo: session.toDTO(),
                userList: liveSession.participants,
                currentServerTime: moment().utc().unix(),
                status: liveSession.status
            };
            return error;
        }
    }

    static _isSubscribedToCourse(user, course) {
        return (course.subscribers.filter(subscriber => subscriber.toString() === user._id.toString())).length > 0;
    }

    static _isOwner(user, course) {
        return course.creator.toString() === user._id.toString();
    }

    static* join(sessionParticipant, sessionId) {
        const liveSession = yield LiveSessionRepository._getOrCreate(sessionId);
        liveSession.participants.addToSet(sessionParticipant);
        sessionParticipant.session = liveSession;
        yield sessionParticipant.save();
        yield liveSession.save();
        return yield liveSession.populate('session').execPopulate();
    }

    static* _getOrCreate(sessionId) {
        const liveSession = yield LiveSessionModel.findOne({session: sessionId}).exec();
        if (!liveSession)
            return yield LiveSessionModel.create({session: sessionId, status: liveSessionStatus.NOT_STARTED});
        return liveSession;
    }

    static* leave(sessionParticipant, sessionId) {
        yield LiveSessionModel.update({session: sessionId}, {$pullAll: {participants: [sessionParticipant]}}, {multi: true});
        return yield LiveSessionModel.findOne({
            session: sessionId,
            participants: {$in: [sessionParticipant]}
        });
    }

    static* isCanStart(user, sessionId) {
        const session = yield SessionModel.findOne({_id: sessionId}).populate({
            path: 'course',
            match: {creator: user}
        }).exec();
        if (!session) {
            return notFoundError(404, 'Session is not found');
        }
        const currentTime = moment().utc().unix();
        const sessionStartTime = moment(session.startAt).utc().unix();
        if (currentTime < sessionStartTime) {
            return baseError(201, 'Please wait until the session starts');
        }
        const liveSession = yield LiveSessionRepository._getOrCreate(sessionId);
        if (liveSession.status === liveSessionStatus.FINISHED) {
            return validationError('Session is finished');
        }
    }

    static* start(sessionId) {
        return yield LiveSessionRepository._changeSessionStatus(sessionId, liveSessionStatus.STARTED);
    }

    static* isCanFinish(user, sessionId) {
        const session = yield SessionModel.findOne({_id: sessionId}).populate({
            path: 'course',
            match: {creator: user}
        }).exec();
        if (!session) {
            return notFoundError(404, 'Session is not found');
        }
    }

    static* finish(sessionId) {
        return yield LiveSessionRepository._changeSessionStatus(sessionId, liveSessionStatus.FINISHED);
    }

    static* _changeSessionStatus(sessionId, status) {
        const liveSession = yield LiveSessionRepository._getOrCreate(sessionId);
        liveSession.status = status;
        yield liveSession.save();
        return yield liveSession.populate('session').execPopulate();
    }
}

module.exports = LiveSessionRepository;
