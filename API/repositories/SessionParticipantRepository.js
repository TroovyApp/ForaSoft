'use strict';

const SessionParticipantModel = require('../schemas/SessionParticipantSchema');

class SessionParticipantRepository {
    static* findByUser(user) {
        return yield SessionParticipantModel.find({user}).populate('session').exec();
    }

    static* getOrCreate(user, socketId) {
        const participant = yield SessionParticipantModel.findOne({user, socketId}).exec();
        if (participant)
            return participant;
        return yield SessionParticipantModel.create({user, socketId});
    }

    static* findBySocketIdAndSessionId(socketId, sessionId) {
        return yield SessionParticipantModel.findOne({socketId}).populate({
            path: 'session',
            match: {session: sessionId}
        }).exec();
    }

    static* findAllBySocketId(socketId){
        return yield SessionParticipantModel.find({socketId}).populate({
            path: 'session'
        }).exec();
    }
}

module.exports = SessionParticipantRepository;
