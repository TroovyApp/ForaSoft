'use strict';

const wrap = require('co').wrap;
const moment = require('moment');

const sessionRoute = require('../routes/SessionRoute');
const internalRoute = require('../routes/InternalRoute');

const UserRepository = require('../../repositories/UserRepository');
const SessionParticipantRepository = require('../../repositories/SessionParticipantRepository');
const LiveSessionRepository = require('../../repositories/LiveSessionRepository');

const accessDeniedError = require('../../helpers/apiError').accessDeniedError;
const userDisabledError = require('../../helpers/apiError').userDisabledError;

const iceServers = require('../../config').iceServers;

const apiResponse = require('../../helpers/apiResponse');

/**
 * @apiDefine UserListEventResponse
 * @apiSuccessExample {json} User list response:
 * {
 *   "userList": ["59a57aa142d91c369c6d914b", "599da4afbba8422d344b4fde"]
 * }
 *
 * */

/**
 * @apiDefine SessionEventResponse
 * @apiSuccessExample {json} Session Event response:
 * {
 *   "currentServerTime": "1507817764",
 *   "sessionInfo": {
 *      "id": "59a57aa142d91c369c6d914b",
 *      "title": "test",
 *      "description": "test",
 *      "duration": 45,
 *      "courseId": "599da4afbba8422d344b4fde",
 *      "startAt": 1504017058,
 *      "createdAt": 1504017057,
 *      "updatedAt": 1504017057
 *   },
 *   "userList": ["59a57aa142d91c369c6d914b", "599da4afbba8422d344b4fde"],
 *   "status": 0
 * }
 *
 * */

class SessionController {
    constructor() {
        this._listen();
    }

    _listen() {
        sessionRoute.on('session:join', wrap(this.join.bind(this)));
        sessionRoute.on('session:leave', wrap(this.leave.bind(this)));
        sessionRoute.on('release', wrap(this.release.bind(this)));
    }

    /**
     * @api {event} session:join
     * @apiVersion 1.0.0
     * @apiName JoinSessionEvent
     * @apiDescription Event to join to session. Dispatch session:userList to all in room, session:forceLogout to another user's socket
     * @apiGroup Sessions Socket Events
     *
     * @apiParam {Object} data Auth data
     * @apiParamExample {json} AuthData-Example:
     * {
     *      "accessToken": "1",
     *      "sessionId": "59a66b324bd4b10ba46ae757"
     * }
     * @apiParam {Function} callback Function for execution after joining
     *
     * @apiUse SessionEventResponse
     * @apiUse AccessDeniedError
     * @apiUse UserDisabledError
     * @apiUse ValidationError
     * @apiUse NotFoundError
     * @apiError (Error 5xx) SessionFinishedError
     *
     * @apiErrorExample {json} Session finished error response:
     *
     * {
     *      "code": 503,
     *      "error": "Session is finished",
     *      "session": {
     *          "currentServerTime": "1507817764",
     *          "sessionInfo": {
     *             "id": "59a57aa142d91c369c6d914b",
     *             "title": "test",
     *             "description": "test",
     *             "duration": 45,
     *             "courseId": "599da4afbba8422d344b4fde",
     *             "startAt": 1504017058,
     *             "createdAt": 1504017057,
     *             "updatedAt": 1504017057
     *          },
     *          "userList": ["59a57aa142d91c369c6d914b", "599da4afbba8422d344b4fde"],
     *          "status": 0,
     *          "iceServers": {
     *              "stuns": [{
     *                   "url": "stun.l.google.com:19302"
     *                   },
     *                   {
     *                       "url": "stun1.l.google.com:19302"
     *                   }],
     *              "turns": [{
     *                   "url": "turn:255.255.255.255:9999",
     *                   "username": "*******",
     *                   "credential": "********"
     *               }]
     *           }
     *     }
     * }
     * */
    * join(socket, data, callback) {
        const {accessToken, sessionId} = data;
        const user = yield UserRepository.findByAccessToken(accessToken);

        const error = yield this._validateJoinParameters(data, user);
        if (error) {
            return callback(error);
        }

        const sessionParticipant = yield SessionParticipantRepository.getOrCreate(user, socket.id);
        const liveSession = yield LiveSessionRepository.join(sessionParticipant, sessionId);
        internalRoute.emit('internal:connect', socket, sessionId, user._id.toString());

        callback(null, {
            sessionInfo: liveSession.session.toDTO(),
            userList: liveSession.participants,
            currentServerTime: moment().utc().unix(),
            status: liveSession.status,
            iceServers: iceServers
        });

        yield this._forceLogout(socket, user);
        internalRoute.emit('internal:emitToRoom', socket, sessionId, 'session:userList', {userList: liveSession.participants});
    }

    * _validateJoinParameters(data, user) {
        const {sessionId} = data;
        if (!user) {
            return accessDeniedError();
        }
        if (user.isDisabled) {
            return userDisabledError();
        }
        const sessionJoinError = yield LiveSessionRepository.isCanJoin(user, sessionId);
        if (sessionJoinError) {
            return sessionJoinError;
        }
    }

    * _forceLogout(socket, user) {
        const participants = yield SessionParticipantRepository.findByUser(user);
        const invalidParticipants = participants.filter(participant => {
            return participant.socketId !== socket.id;
        });
        yield invalidParticipants.map(participant => {
            const sessionId = participant.session.session.toString();
            internalRoute.emit('internal:disconnect', participant.socketId, sessionId, participant.user.toString());
            socket.to(participant.socketId).emit('session:forceLogout');
            return this._deleteParticipant(participant, sessionId);
        });
    }


    /**
     * @api {event} session:leave
     * @apiVersion 1.0.0
     * @apiName LeaveSessionEvent
     * @apiDescription Event to leave session. Dispatch session:userList to all in room
     * @apiGroup Sessions Socket Events
     *
     * @apiParam {Object} data Auth data
     * @apiParamExample {json} AuthData-Example:
     * {
     *      "sessionId": "59a66b324bd4b10ba46ae757"
     * }
     * @apiParam {Function} callback Function for execution after leaving
     *
     * @apiUse EmptySuccessResponse
     * @apiUse AccessDeniedError
     * @apiUse UserDisabledError
     * @apiUse ValidationError
     * @apiUse NotFoundError
     * */
    * leave(socket, data, callback) {
        const {sessionId} = data;
        const participant = yield SessionParticipantRepository.findBySocketIdAndSessionId(socket.id, sessionId);
        if (!participant)
            return callback(null, apiResponse({}));

        internalRoute.emit('internal:disconnect', participant.socketId, sessionId, participant.user.toString());
        yield this._deleteParticipant(participant, sessionId);
        callback(null, apiResponse({}));

    }

    /**
     * @api {event} session:userList
     * @apiVersion 1.0.0
     * @apiName UserListSessionEvent
     * @apiDescription Event with sessions' participants list
     * @apiGroup Sessions Socket Events
     *
     * @apiUse UserListEventResponse
     * */
    * _deleteParticipant(participant, sessionId) {
        const leavedSession = yield LiveSessionRepository.leave(participant, sessionId);
        yield participant.remove();
        if (!leavedSession)
            return;
        internalRoute.emit('internal:emitToAllInRoom', sessionId, 'session:userList', {userList: leavedSession.participants});
    }

    * release(socket) {
        const participants = yield SessionParticipantRepository.findAllBySocketId(socket.id);
        yield participants.map(participant => {
            const sessionId = participant.session.session.toString();
            internalRoute.emit('internal:disconnect', participant.socketId, sessionId, participant.user.toString());
            return this._deleteParticipant(participant, sessionId);
        });
    }
}

module.exports = SessionController;
