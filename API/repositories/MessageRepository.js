'use strict';

const moment = require('moment');

const MessageModel = require('../schemas/MessageSchema');
const LiveSessionModel = require('../schemas/LiveSessionSchema');

class MessageRepository {
    static* create(participant, sessionId, text) {
        yield participant.populate('user').execPopulate();
        const sender = participant.user;
        const timestamp = moment().utc().valueOf();
        const liveSession = yield LiveSessionModel.findOne({session: sessionId}).exec();

        const message = yield MessageModel.create({session: liveSession, text, sender, timestamp});

        liveSession.messages.addToSet(message);
        yield liveSession.save();

        return message;
    }

    static* getMessagesBySessionId(sessionId, count, page) {
        const liveSession = yield LiveSessionModel.findOne({session: sessionId}).exec();
        const skip = Number(count) * (Number(page) - 1) >= 0 ? Number(count) * (Number(page) - 1) : 0;
        return yield MessageModel.find({session: liveSession})
            .sort({timestamp: -1})
            .limit(Number(count))
            .skip(skip)
            .populate('sender')
            .exec();
    }
}

module.exports = MessageRepository;
