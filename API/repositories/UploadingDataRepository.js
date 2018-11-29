'use strict';

const UploadingDataModel = require('../schemas/UploadingDataSchema');
const getUploadingDataPath = require('../utils/getUploadingDataPath');

class UploadingDataRepository {
    static* deleteUploadingData(dataId) {
        return yield UploadingDataModel.remove({_id: dataId});
    }

    static* getOrCreateUploadingData(chunkData, ext) {
        const {dataId, entityId, entityType} = chunkData;
        const filepath = yield getUploadingDataPath(entityId, ext);
        return yield Boolean(dataId)
            ? UploadingDataRepository.getUploadingData(dataId)
            : UploadingDataRepository._createUploadingData(entityId, entityType, filepath);
    }

    static* _createUploadingData(entityId, entityType, filePath) {
        return yield UploadingDataModel.create({entityId, entityType, filePath});
    }

    static* getUploadingData(dataId) {
        return yield UploadingDataModel.findOne({_id: dataId}).exec();
    }
}

module.exports = UploadingDataRepository;
