'use strict';

const wrap = require('co').wrap;

const streamRoute = require('../routes/StreamRoute');
const internalRoute = require('../routes/InternalRoute');

const VideoChatEstablisher = require('../utils/VideoChatEstablisher');
const SessionParticipantRepository = require('../../repositories/SessionParticipantRepository');

const accessDeniedError = require('../../helpers/apiError').accessDeniedError;
const apiResponse = require('../../helpers/apiResponse');

class StreamController {
    /**
     * @apiDefine StreamInfoResponse
     * @apiSuccessExample {json} Stream info response:
     * {
    *   "label": "59a57aa142d91c369c6d914b",
    *   "isVideoEnabled": true
    * }
     *
     * */

    /**
     * @apiDefine AnswerSdpResponse
     * @apiSuccessExample {json} Answer SDP response:
     * {
     *   "answerSdp": ""
     * }
     * */

    /**
     * @apiDefine CandidateResponse
     * @apiSuccessExample {json} Candidate response:
     * {
     *   "candidate": "",
     *   "label": "59a57aa142d91c369c6d914b"
     * }
     * */

    constructor() {
        this._listen();
        this.establisher = new VideoChatEstablisher();
    }

    _listen() {
        streamRoute.on('stream:info', wrap(this.getStreamInfo.bind(this)));
        streamRoute.on('stream:publish', wrap(this.publishStream.bind(this)));
        streamRoute.on('stream:play', wrap(this.playStream.bind(this)));
        streamRoute.on('stream:candidate', this.onIceCandidate.bind(this));
        streamRoute.on('stream:stop', wrap(this.stopStream.bind(this)));
        streamRoute.on('stream:video:enable', wrap(this.enableVideoStream).bind(this));
        streamRoute.on('stream:video:disable', wrap(this.disableVideoStream).bind(this));
        streamRoute.on('stream:connected', wrap(this.onStreamConnected).bind(this));
        internalRoute.on('stream:release', wrap(this.release.bind(this)));
    }

    /**
     * @api {event} stream:info
     * @apiVersion 1.0.0
     * @apiName StreamInfoEvent
     * @apiDescription Event to get stream info
     * @apiGroup Streams Socket Events
     *
     * @apiParam {Object} data Stream data
     * @apiParamExample {json} StreamData-Example:
     * {
     *      "sessionId": "59a66b324bd4b10ba46ae757"
     * }
     * @apiParam {Function} callback Function for execution after getting stream info
     *
     * @apiUse AccessDeniedError
     * @apiUse StreamInfoResponse
     * */
    * getStreamInfo(socket, data, callback) {
        const error = yield this._validateCredentials(socket, data);
        if (error)
            return callback(error);
        return yield this.establisher.getStreamInfo(data, callback);
    }

    /**
     * @api {event} stream:connected
     * @apiVersion 1.0.0
     * @apiName StreamConnectedEvent
     * @apiDescription Event when peerConnection processed answerSDP
     * @apiGroup Streams Socket Events
     *
     * @apiParam {Object} data Stream data
     * @apiParamExample {json} StreamData-Example:
     * {
     *      "sessionId": "59a66b324bd4b10ba46ae757",
     *      "isVideoEnabled": true,
     *      "label": "59a57aa142d91c369c6d914b"
     * }
     * @apiParam {Function} callback Function for execution after
     *
     * @apiUse AccessDeniedError
     * @apiUse EmptySuccessResponse
     * */
    * onStreamConnected(socket, data, callback) {
        const error = yield this._validateCredentials(socket, data);
        if (error)
            return callback(error);
        return this.establisher.onStreamConnected(socket, data, callback);
    }

    /**
     * @api {event} stream:publish
     * @apiVersion 1.0.0
     * @apiName StreamPublishEvent
     * @apiDescription Event to publish stream. Dispatch event stream:published to all in room
     * @apiGroup Streams Socket Events
     *
     * @apiParam {Object} data Stream data
     * @apiParamExample {json} StreamData-Example:
     * {
     *      "sessionId": "59a66b324bd4b10ba46ae757",
     *      "offerSdp": "",
     *      "isVideoEnabled": true
     * }
     * @apiParam {Function} callback Function for execution after publishing stream
     *
     * @apiUse AccessDeniedError
     * @apiUse AnswerSdpResponse
     * */
    * publishStream(socket, data, callback) {
        const error = yield this._validateCredentials(socket, data);
        if (error)
            return callback(error);
        return yield this.establisher.publishStream(socket, data, callback);
    }

    /**
     * @api {event} stream:play
     * @apiVersion 1.0.0
     * @apiName StreamPlayEvent
     * @apiDescription Event to play stream
     * @apiGroup Streams Socket Events
     *
     * @apiParam {Object} data Stream data
     * @apiParamExample {json} StreamData-Example:
     * {
     *      "sessionId": "59a66b324bd4b10ba46ae757",
     *      "offerSdp": "",
     *      "label": "59a57aa142d91c369c6d914b"
     * }
     * @apiParam {Function} callback Function for execution after playing stream
     *
     * @apiUse AccessDeniedError
     * @apiUse AnswerSdpResponse
     * */
    * playStream(socket, data, callback) {
        const error = yield this._validateCredentials(socket, data);
        if (error)
            return callback(error);
        return yield this.establisher.playStream(socket, data, callback);
    }

    /**
     * @api {event} stream:candidate
     * @apiVersion 1.0.0
     * @apiName StreamCandidateEvent
     * @apiDescription Event to send stream candidate
     * @apiGroup Streams Socket Events
     *
     * @apiParam {Object} data Stream data
     * @apiParamExample {json} StreamData-Example:
     * {
     *      "sessionId": "59a66b324bd4b10ba46ae757",
     *      "userId": "59a57aa142d91c369c6d914b",
     *      "label": "59a57aa142d91c369c6d914b",
     *      "candidate": ""
     * }
     * @apiParam {Function} callback Function for execution after playing stream
     * @apiUse EmptySuccessResponse
     * */
    onIceCandidate(socket, data, callback) {
        return this.establisher.onIceCandidate(data, callback);
    }

    /**
     * @api {event} stream:stop
     * @apiVersion 1.0.0
     * @apiName StreamStopEvent
     * @apiDescription Event to stop stream
     * @apiGroup Streams Socket Events
     *
     * @apiParam {Object} data Stream data
     * @apiParamExample {json} StreamData-Example:
     * {
     *      "sessionId": "59a66b324bd4b10ba46ae757"
     * }
     * @apiParam {Function} callback Function for execution after stopping stream
     * @apiUse AccessDeniedError
     * @apiUse EmptySuccessResponse
     * */
    * stopStream(socket, data, callback) {
        const error = yield this._validateCredentials(socket, data);
        if (error)
            return callback(error);
        const {sessionId} = data;
        const participant = yield SessionParticipantRepository.findBySocketIdAndSessionId(socket.id, sessionId);
        yield this.release(participant);
        yield participant.populate('user').execPopulate();
        console.log('Release stream ', participant.user.name);
        callback(null, apiResponse({}));
    }

    /**
     * @api {event} stream:video:enable
     * @apiVersion 1.0.0
     * @apiName EnableVideoEvent
     * @apiDescription Event to enable video of stream. Dispatch stream:video:enabled to all in room
     * @apiGroup Streams Socket Events
     *
     * @apiParam {Object} data Stream data
     * @apiParamExample {json} StreamData-Example:
     * {
     *      "sessionId": "59a66b324bd4b10ba46ae757"
     * }
     * @apiParam {Function} callback Function for execution after enabling video
     * @apiUse AccessDeniedError
     * @apiUse EmptySuccessResponse
     * */
    * enableVideoStream(socket, data, callback) {
        const error = yield this._validateCredentials(socket, data);
        if (error)
            return callback(error);
        yield this.establisher.enableVideo(socket, data, callback);
    }

    /**
     * @api {event} stream:video:disable
     * @apiVersion 1.0.0
     * @apiName DisableVideoEvent
     * @apiDescription Event to disable video of stream. Dispatch stream:video:disabled to all in room
     * @apiGroup Streams Socket Events
     *
     * @apiParam {Object} data Stream data
     * @apiParamExample {json} StreamData-Example:
     * {
     *      "sessionId": "59a66b324bd4b10ba46ae757"
     * }
     * @apiParam {Function} callback Function for execution after enabling video
     * @apiUse AccessDeniedError
     * @apiUse EmptySuccessResponse
     * */
    * disableVideoStream(socket, data, callback) {
        const error = yield this._validateCredentials(socket, data);
        if (error)
            return callback(error);
        yield this.establisher.disableVideo(socket, data, callback);
    }

    * release(participant) {
        yield this.establisher.stopStream(participant);
    }

    * _validateCredentials(socket, data) {
        const {sessionId} = data;
        const participant = yield SessionParticipantRepository.findBySocketIdAndSessionId(socket.id, sessionId);
        if (!Boolean(participant))
            return accessDeniedError();
    }
}

module.exports = StreamController;
