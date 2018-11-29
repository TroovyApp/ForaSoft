'use strict';

const mongoose = require('mongoose');
const Schema = mongoose.Schema;
const moment = require('moment');

const attachmentTypes = require('../constants/attachmentTypes');
const FileUtils = require('../helpers/FileUtils');


const AttachmentSchema = new Schema({
    type: Number,
    params: {type: Schema.Types.Mixed, default: {}},
    course: {type: Schema.ObjectId, ref: 'Course'},
    createdAt: {type: Date},
    updatedAt: {type: Date}
}, {collection: 'Attachment'});

AttachmentSchema.pre('save', function (next) {
    if (!this.createdAt)
        this.createdAt = moment().utc().valueOf();
    this.updatedAt = moment().utc().valueOf();
    next();
});

AttachmentSchema.pre('update', function (next) {
    this.update({}, {$set: {updatedAt: moment().utc().valueOf()}});
    next();
});

AttachmentSchema.pre('remove', function (next) {
    try {
        switch (this.type) {
            case attachmentTypes.VIDEO:
                if (this.params.fileUrl)
                    FileUtils.deleteFile(this.params.fileUrl);
                break;
        }
        next();
    }
    catch (err) {
        throw err;
    }
});

AttachmentSchema.methods.toDTO = function () {
    switch (this.type) {
        case attachmentTypes.VIDEO:
            return toVideoDTO.call(this);
    }
};

function toVideoDTO() {
    const dto = getDefaultDTO.call(this);
    dto.fileUrl = this.params.fileUrl;
    dto.fileThumbnailUrl = this.params.fileThumbnailUrl;
    return dto;
}

function getDefaultDTO() {
    return {
        id: this._id,
        type: this.type,
        createdAt: moment(this.createdAt).unix(),
        updatedAt: moment(this.updatedAt).unix()
    }
}

module.exports = mongoose.model('Attachment', AttachmentSchema);
