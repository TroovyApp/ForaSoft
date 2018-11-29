'use strict';

const MessageRepository = require('../repositories/MessageRepository');

const validateObjectId = require('../helpers/validators/validateObjectId');
const validationError = require('../helpers/apiError').validationError;

const getMessages = function* (sessionId, count, page) {
    if (!validateObjectId(sessionId)) {
        throw validationError('Session id is not valid');
    }
    return yield MessageRepository.getMessagesBySessionId(sessionId, count, page);
};

module.exports = {
    getMessages
};
