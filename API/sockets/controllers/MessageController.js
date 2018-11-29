'use strict';

const wrap = require('co').wrap;

const messageRoute = require('../routes/MessageRoute');

const SessionParticipantRepository = require('../../repositories/SessionParticipantRepository');
const MessageSender = require('../utils/MessageSender');

const accessDeniedError = require('../../helpers/apiError').accessDeniedError;

class StreamController {
    /**
     * @apiDefine MessageResponse
     * @apiSuccessExample {json} Message response:
     * {
     *   "messageId": "59a57aa142d91c369c6d914b",
     *   "senderId": "59a57aa142d91c369c6d914b",
     *   "senderName": "Vladislav",
     *   "senderImageUrl": "/uploads/image-963o9t506w8hnf8fvo6tuik9-1503303601422.jpg",
     *   "text": "Text",
     *   "timestamp": 1504017057,
     *   "isHighlighted": false
     * }
     *
     * */

    constructor() {
        this._listen();
        this.sender = new MessageSender();
    }

    _listen() {
        messageRoute.on('message:send', wrap(this.sendMessage.bind(this)));
    }

    /**
     * @api {event} message:send
     * @apiVersion 1.0.0
     * @apiName MessageSendEvent
     * @apiDescription Event to send message. Dispatch event message:received to room
     * @apiGroup Messages Socket Events
     *
     * @apiParam {Object} data Message data
     * @apiParamExample {json} MessageData-Example:
     * {
     *      "sessionId": "59a66b324bd4b10ba46ae757",
     *      "text": "Text"
     * }
     * @apiParam {Function} callback Function for execution after sending message
     *
     * @apiUse AccessDeniedError
     * @apiUse MessageResponse
     * */
    * sendMessage(socket, data, callback) {
        const error = yield this._validateCredentials(socket, data);
        if (error)
            return callback(error);
        return yield this.sender.send(socket, data, callback);
    }

    * _validateCredentials(socket, data) {
        const {sessionId} = data;
        const participant = yield SessionParticipantRepository.findBySocketIdAndSessionId(socket.id, sessionId);
        if (!Boolean(participant))
            return accessDeniedError();
    }
}

module.exports = StreamController;