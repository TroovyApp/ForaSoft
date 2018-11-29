'use strict';

const mongoose = require('mongoose');
const Schema = mongoose.Schema;
const moment = require('moment');

const CourseModel = require('./CourseSchema');

const FileUtils = require('../helpers/FileUtils');
const {INTRO_IMAGE, INTRO_VIDEO} = require('../constants/uploadingDataConstants').uploadingDataTypes;

const IntroSchema = new Schema({
    type: Number,
    fileUrl: {type: String},
    fileThumbnailUrl: {type: String},
    fileSharingUrl: {type: String},
    course: {type: Schema.ObjectId, ref: 'Course'},
    order: Number,
    createdAt: {type: Date},
    updatedAt: {type: Date}
}, {collection: 'Intro'});

IntroSchema.pre('save', function (next) {
    if (!this.createdAt)
        this.createdAt = moment().utc().valueOf();
    this.updatedAt = moment().utc().valueOf();
    next();
});

IntroSchema.pre('update', function (next) {
    this.update({}, {$set: {updatedAt: moment().utc().valueOf()}});
    next();
});

IntroSchema.pre('remove', function (next) {
    try {
        CourseModel.update({},
            {$pull: {intro: this._id}},
            {multi: true})
            .exec();
        if (this.fileUrl)
            FileUtils.deleteFile(this.fileUrl);
        if (this.fileThumbnailUrl)
            FileUtils.deleteFile(this.fileThumbnailUrl);
        FileUtils.deletePublicDir(this._id.toString());
        next();
    } catch (err) {
        throw err;
    }
});

IntroSchema.methods.toDTO = function () {
    return {
        id: this._id,
        type: this.type,
        fileUrl: this.fileUrl,
        fileThumbnailUrl: this.fileThumbnailUrl,
        fileSharingUrl: this.fileSharingUrl,
        order: this.order,
        createdAt: moment(this.createdAt).unix(),
        updatedAt: moment(this.updatedAt).unix(),
        isImage: this.type === INTRO_IMAGE,
        isVideo: this.type === INTRO_VIDEO
    }
};

module.exports = mongoose.model('Intro', IntroSchema);
