'use strict';
const mongoose = require('mongoose');
const moment = require('moment');
const Schema = mongoose.Schema;

const LiveSessionSchema = new Schema({
    status: {type: Number},
    session: {type: Schema.ObjectId, ref: 'Session'},
    participants: [{type: Schema.ObjectId, ref: 'SessionParticipant', default: []}],
    mediaElements: [{type: Schema.ObjectId, ref: 'MediaElement', default: []}],
    messages: [{type: Schema.ObjectId, ref: 'Message', default: []}],
    createdAt: {type: Date},
    updatedAt: {type: Date},
    pipeline: {type: Schema.ObjectId, ref: 'MediaElement'}
}, {collection: 'LiveSession'});

LiveSessionSchema.pre('save', function (next) {
    if (!this.createdAt)
        this.createdAt = moment().utc().valueOf();
    this.updatedAt = moment().utc().valueOf();
    next();
});

LiveSessionSchema.pre('update', function (next) {
    this.update({}, {$set: {updatedAt: moment().utc().valueOf()}});
    next();
});

module.exports = mongoose.model('LiveSession', LiveSessionSchema);
