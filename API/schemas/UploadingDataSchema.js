const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const uploadStatus = require('../constants/uploadingDataConstants').uploadingDataStatus;

const UploadingDataSchema = new Schema({
    entityType: Number,
    entityId: String,
    filePath: String,
    status: {type: Number, default: uploadStatus.NOT_UPLOADED}
}, {collection: 'UploadingData'});

UploadingDataSchema.methods.toDTO = function () {
    return {
        entityType: this.entityType,
        entityId: this.entityId,
        dataId: this._id
    };
};

module.exports = mongoose.model('UploadingData', UploadingDataSchema);
