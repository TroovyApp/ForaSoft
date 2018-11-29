'use strict';
const mongoose = require('mongoose');
const moment = require('moment');
const Schema = mongoose.Schema;

const internalRoute = require('../sockets/routes/InternalRoute');

const SessionParticipantSchema = new Schema({
    socketId: {type: String},
    user: {type: Schema.ObjectId, ref: 'User'},
    session: {type: Schema.ObjectId, ref: 'LiveSession'},
    createdAt: {type: Date},
    updatedAt: {type: Date}
}, {collection: 'SessionParticipant'});

SessionParticipantSchema.pre('save', function (next) {
    if (!this.createdAt)
        this.createdAt = moment().utc().valueOf();
    this.updatedAt = moment().utc().valueOf();
    next();
});

SessionParticipantSchema.pre('update', function (next) {
    this.update({}, {$set: {updatedAt: moment().utc().valueOf()}});
    next();
});

SessionParticipantSchema.pre('remove', function (next) {
    internalRoute.emit('stream:release', this);
    next();
});

module.exports = mongoose.model('SessionParticipant', SessionParticipantSchema);