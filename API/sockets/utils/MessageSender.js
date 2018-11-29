'use strict';

const SessionParticipantRepository = require('../../repositories/SessionParticipantRepository');
const MessageRepository = require('../../repositories/MessageRepository');

const internalRoute = require('../routes/InternalRoute');
const apiResponse = require('../../helpers/apiResponse');

class MessageSender {
    /**
     * @api {event} message:received
     * @apiVersion 1.0.0
     * @apiName MessageReceivedEvent
     * @apiDescription Event when new message received
     * @apiGroup Messages Socket Events
     *
     * @apiUse MessageResponse
     * */
    * send(socket, data, callback) {
        const {sessionId, text} = data;
        const participant = yield SessionParticipantRepository.findBySocketIdAndSessionId(socket.id, sessionId);
        const message = yield MessageRepository.create(participant, sessionId, text);
        const dto = message.toDTO();
        callback && callback(null, apiResponse(dto));
        internalRoute.emit('internal:emitToRoom', socket, sessionId, 'message:received', dto);
    }
}

module.exports = MessageSender;
