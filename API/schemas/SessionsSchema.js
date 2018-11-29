const mongoose = require('mongoose');
const moment = require('moment');
const Schema = mongoose.Schema;

const fromMinutesToSeconds = require('../utils/fromMinutesToSeconds');

const SESSION_TIME_STATUS = require('../constants/timeStatus');
const ALLOWED_TIME = require('../constants/sessionConstants').SESSION_NOT_EDITING_TIME;


const SessionsSchema = new Schema({
    title: String,
    description: String,
    startAt: {type: Date},
    duration: {type: Number},
    course: {type: Schema.ObjectId, ref: 'Course'},
    createdAt: {type: Date},
    updatedAt: {type: Date}
}, {collection: 'Session'});

SessionsSchema.pre('save', function (next) {
    if (!this.createdAt)
        this.createdAt = moment().utc().valueOf();
    this.updatedAt = moment().utc().valueOf();
    next();
});

SessionsSchema.pre('update', function (next) {
    this.update({}, {$set: {updatedAt: moment().utc().valueOf()}});
    next();
});

SessionsSchema.pre('remove', function (next) {
    if(Boolean(this.course.update) && typeof this.course.update === 'function' ) // if course was be populate
        this.course.update({ $pull: { sessions: this.id } }).exec();
    next();
});

SessionsSchema.virtual('timeStatus').get(function () {
    if (!this)
        return SESSION_TIME_STATUS.NONE;
    const currentTime = moment().utc().unix();
    const sessionEndTime = moment(this.startAt).utc().unix() + fromMinutesToSeconds(this.duration);
    const sessionStartTime = moment(this.startAt).utc().unix() - ALLOWED_TIME;

    if (currentTime < sessionStartTime) {
        return SESSION_TIME_STATUS.UPCOMING;
    }
    if (sessionStartTime <= currentTime && currentTime <= sessionEndTime) {
        return SESSION_TIME_STATUS.STARTED;
    }
    if (currentTime > sessionEndTime) {
        return SESSION_TIME_STATUS.FINISHED;
    }
});

SessionsSchema.methods.toDTO = function () {
    return {
        id: this._id,
        title: this.title,
        description: this.description,
        duration: this.duration,
        courseId: this.course._id ? this.course._id.toString() : this.course.toString(),
        timeStatus: this.timeStatus,
        startAt: moment(this.startAt).unix(),
        createdAt: moment(this.createdAt).unix(),
        updatedAt: moment(this.updatedAt).unix()
    }
};

SessionsSchema.methods.toListDTO = function () {
    return {
        id: this._id,
        createdAt: moment(this.createdAt).unix(),
        updatedAt: moment(this.updatedAt).unix()
    }
};

module.exports = mongoose.model('Session', SessionsSchema);
