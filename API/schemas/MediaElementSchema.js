'use strict';
const mongoose = require('mongoose');
const moment = require('moment');
const Schema = mongoose.Schema;

const LiveSessionModel = require('./LiveSessionSchema');
const mediaElementsTypes = require('../constants/mediaElementsConstants').types;

const MediaElementSchema = new Schema({
    liveSession: {type: Schema.ObjectId, ref: 'LiveSession'},
    mediaElementId: {type: String},
    type: {type: String},
    owner: {type: Schema.ObjectId, ref: 'SessionParticipant'},
    createdAt: {type: Date},
    updatedAt: {type: Date},
    isConnected: {type: Boolean, default: false},
    isVideoEnabled: {type: Boolean, default: true}
}, {collection: 'MediaElement'});

MediaElementSchema.pre('save', function (next) {
    if (!this.createdAt)
        this.createdAt = moment().utc().valueOf();
    this.updatedAt = moment().utc().valueOf();
    next();
});

MediaElementSchema.pre('update', function (next) {
    this.update({}, {$set: {updatedAt: moment().utc().valueOf()}});
    next();
});

MediaElementSchema.pre('remove', function (next) {
    LiveSessionModel.update({},
        {$pull: {mediaElements: this._id}},
        {multi: true})
        .exec();
    if (this.type === mediaElementsTypes.PIPELINE) {
        LiveSessionModel.update({pipeline: this._id}, {pipeline: undefined}).exec();
    }
    next();
});

module.exports = mongoose.model('MediaElement', MediaElementSchema);
