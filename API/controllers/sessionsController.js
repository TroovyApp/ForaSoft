'use strict';

const Router = require('router');
const wrap = require('co').wrap;

const auth = require('../helpers/auth');
const apiResponse = require('../helpers/apiResponse');

const validateCreateSessionParameters = require('../helpers/validators/createSessionValidator');

const createSession = require('../domain/sessionsUtils').createSession;
const editSession = require('../domain/sessionsUtils').editSession;
const deleteSession = require('../domain/sessionsUtils').deleteSession;
const findCourse = require('../domain/coursesUtils').findCourseForOwner;
const findUpcomingSessions = require('../domain/coursesUtils').findUpcomingSessions;
const startSession = require('../domain/sessionsUtils').startSession;
const finishSession = require('../domain/sessionsUtils').finishSession;
const findSessionAttachments = require('../domain/sessionsUtils').findSessionAttachments;

const {sendCancelSessionNotification, sendNewSessionNotification} = require('../domain/smsNotifications');
const {scheduleUpcomingSessionTask, cancelUpcomingSessionTask} = require('../domain/taskSchedule/taskManagement');

const router = Router();

/**
 * @apiDefine SessionResponse
 * @apiSuccessExample {json} Session response:
 * {
 *   "code": 200,
 *   "result": {
 *       "id": "59a57aa142d91c369c6d914b",
 *       "title": "test",
 *       "description": "test",
 *       "duration": 45,
 *       "courseId": "599da4afbba8422d344b4fde",
 *       "startAt": 1504017058,
 *       "createdAt": 1504017057,
 *       "updatedAt": 1504017057
 *   }
 *}
 * */
/**
 * @apiDefine SessionListResponse
 * @apiSuccessExample {json} Session list response:
 * {
 *   "code": 200,
 *   "result": [
 *                  {
 *                      "id": "59a57aa142d91c369c6d914b",
 *                      "title": "test",
 *                      "description": "test",
 *                      "duration": 45,
 *                      "courseId": "599da4afbba8422d344b4fde",
 *                      "startAt": 1504017058,
 *                      "createdAt": 1504017057,
 *                      "updatedAt": 1504017057
 *                  },
 *                  {
 *                      "id": "59a57aa142d91c369c6d914b",
 *                      "title": "test2",
 *                      "description": "test2",
 *                      "duration": 45,
 *                      "courseId": "599da4afbba8422d344b4fde",
 *                      "startAt": 1504017058,
 *                      "createdAt": 1504017057,
 *                      "updatedAt": 1504017057
 *                  }
 *   ]
 *}
 * */
/**
 * @api {post} /api/v1/sessions
 * @apiVersion 1.0.0
 * @apiName CreateSession
 * @apiDescription Create session
 * @apiGroup Sessions
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} courseId Id of session's course
 * @apiParam {String} title Session title
 * @apiParam {String} description Session description
 * @apiParam {Number} startAt Session start time timestamp in UTC
 * @apiParam {Number} duration Session duration. Could be 30, 45, 60
 *
 * @apiUse SessionResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * @apiUse ValidationError
 * @apiUse NotFoundError
 * */
router.post('', auth, wrap(function* (req, res) {
    const validationError = validateCreateSessionParameters(req.body);
    if (validationError) {
        return res.send(validationError);
    }
    const {courseId, title, description, duration, startAt} = req.body;
    try {
        const course = yield findCourse(req.user, courseId, false);
        const session = yield createSession(course, title, description, duration, startAt);
        yield sendNewSessionNotification(session);
        scheduleUpcomingSessionTask(session);
        return res.send(apiResponse(session.toDTO()));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {get} /api/v1/sessions/upcoming
 * @apiVersion 1.0.0
 * @apiName UpcomingSessions
 * @apiDescription Upcoming sessions list
 * @apiGroup Sessions
 *
 * @apiParam {String} accessToken Access token
 *
 * @apiUse SessionListResponse
 * @apiUse UserDisabledError
 * */
router.get('/upcoming', auth, wrap(function* (req, res) {
    try {
        const sessions = yield findUpcomingSessions(req.user);
        return res.send(apiResponse(sessions));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {post} /api/v1/sessions/start/:sessionId
 * @apiVersion 1.0.0
 * @apiName StartSession
 * @apiDescription Start session. Dispatch event session:started to all in room
 * @apiGroup Sessions
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} sessionId Session's id should be provided in URL
 *
 * @apiUse EmptySuccessResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * @apiUse ValidationError
 * @apiUse NotFoundError
 * */
/**
 * @api {event} session:started
 * @apiVersion 1.0.0
 * @apiName SessionStartedEvent
 * @apiDescription Event when streamer started session
 * @apiGroup Sessions Socket Events
 *
 * @apiUse SessionEventResponse
 * */
router.post('/start/:sessionId', auth, wrap(function* (req, res) {
    const {sessionId} = req.params;
    try {
        yield startSession(req.user, sessionId);
        return res.send(apiResponse({}));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {post} /api/v1/sessions/finish/:sessionId
 * @apiVersion 1.0.0
 * @apiName FinishSession
 * @apiDescription Finish session. Dispatch event session:finished to all in room
 * @apiGroup Sessions
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} sessionId Session's id should be provided in URL
 *
 * @apiUse EmptySuccessResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * @apiUse ValidationError
 * @apiUse NotFoundError
 * */
/**
 * @api {event} session:finished
 * @apiVersion 1.0.0
 * @apiName SessionFinishedEvent
 * @apiDescription Event when streamer finished session
 * @apiGroup Sessions Socket Events
 *
 * @apiUse SessionEventResponse
 * */
router.post('/finish/:sessionId', auth, wrap(function* (req, res) {
    const {sessionId} = req.params;
    try {
        yield finishSession(req.user, sessionId);
        return res.send(apiResponse({}));
    } catch (err) {
        return res.send(err);
    }
}));


/**
 * @api {put} /api/v1/sessions/:sessionId
 * @apiVersion 1.0.0
 * @apiName EditSession
 * @apiDescription Edit session
 * @apiGroup Sessions
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} [title] Session title
 * @apiParam {String} [description] Session description
 * @apiParam {Number} [startAt] Session start time timestamp in UTC
 * @apiParam {Number} [duration] Session duration. Could be 30, 45, 60
 *
 * @apiUse SessionResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * @apiUse ValidationError
 * @apiUse NotFoundError
 * @apiErrorExample SessionTimeCrossValidationError
 * {
 *   "code": 400,
 *   "error": "Session time is in past or cross with your other sessions"
 * }
 * @apiErrorExample SessionNotEditableValidationError
 * {
 *   "code": 400,
 *   "error": "You can not edit past sessions or which start less than 10 minutes"
 * }
 * */
router.put('/:sessionId', auth, wrap(function* (req, res) {
    const {sessionId} = req.params;
    try {
        const session = yield editSession(req.user, sessionId, req.body);
        cancelUpcomingSessionTask(session);
        scheduleUpcomingSessionTask(session);
        return res.send(apiResponse(session.toDTO()));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {delete} /api/v1/sessions/:sessionId
 * @apiVersion 1.0.0
 * @apiName DeleteSession
 * @apiDescription Delete session
 * @apiGroup Sessions
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} sessionId Session's id should be provided in URL
 *
 * @apiUse EmptySuccessResponse
 * @apiUse AccessDeniedError
 * @apiUse ValidationError
 * @apiUse NotFoundError
 * */
router.delete('/:sessionId', auth, wrap(function* (req, res) {
    const {sessionId} = req.params;
    try {
        const sessionModel = yield deleteSession(req.user, sessionId);
        if (sessionModel) {
            cancelUpcomingSessionTask(sessionModel);
            yield sendCancelSessionNotification(sessionModel);
        }
        return res.send(apiResponse({}));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {get} /api/v1/sessions/attachments
 * @apiVersion 1.0.0
 * @apiName SessionsAttachments
 * @apiDescription Session attachments list
 * @apiGroup Sessions
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} sessionId Id of session
 *
 * @apiUse AttachmentsListResponse
 * @apiUse UserDisabledError
 * @apiUse AccessDeniedError
 * @apiUse ValidationError
 * @apiUse NotFoundError
 * */
router.get('/attachments', auth, wrap(function* (req, res) {
    try {
        const {sessionId = ''} = req.query;
        const attachments = yield findSessionAttachments(sessionId);
        return res.send(apiResponse(attachments.map(attachment => {
            return attachment.toDTO();
        })));
    } catch (err) {
        return res.send(err);
    }
}));

module.exports = router;
