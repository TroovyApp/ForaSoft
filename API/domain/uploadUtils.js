'use strict';

const path = require('path');
const fs = require('fs');
const randtoken = require('rand-token');

const UploadingDataRepository = require('../repositories/UploadingDataRepository');
const IntroRepository = require('../repositories/IntroRepository');
const AttachmentRepository = require('../repositories/AttachmentRepository');

const FileUtils = require('../helpers/FileUtils');
const promisifyWriteStream = require('../utils/writeStreamPromisify');
const uploadTypes = require('../constants/uploadingDataConstants').uploadingDataTypes;
const uploadStatus = require('../constants/uploadingDataConstants').uploadingDataStatus;
const attachmentTypes = require('../constants/attachmentTypes');
const validateObjectId = require('../helpers/validators/validateObjectId');
const validationError = require('../helpers/apiError').validationError;
const notFoundError = require('../helpers/apiError').notFoundError;
const logger = require('../utils/logger');

const ffmpegManager = require('../helpers/processing/FfmpegManager');
const ThumbnailCommand = require('../helpers/processing/ThumbnailCommand');
const RotateAndCropCommand = require('../helpers/processing/RotateAndCropCommand');
const MiniThumbnailCommand = require('../helpers/processing/MiniThumbnailCommand');
const promisifyCommand = require('../helpers/processing/promisifyCommand');
const uploadHandler = require('../helpers/processing/UploadHandler');

const THUMBNAIL_FORMAT = '.png';
const VIDEO_FORMAT = '.mp4';
const MINI_THUMBNAIL_FORMAT = '.jpg';


const saveChunk = function* (user, chunkPath, data) {
    const validationError = yield isEntityValid(user, data);
    if (validationError) {
        yield cleanUploading(chunkPath, data, true);
        throw validationError;
    }

    const ext = path.extname(chunkPath);
    const uploadingData = yield UploadingDataRepository.getOrCreateUploadingData(data, ext);

    const {isLast} = data;
    const result = yield Boolean(Number(isLast))
        ? _processLastChunk(user, uploadingData, chunkPath, data)
        : _processChunk(uploadingData, chunkPath, data);
    yield cleanUploading(chunkPath, data);
    return result;
};

const isEntityValid = function* (user, entityData) {
    const {entityId, entityType} = entityData;
    if (!validateObjectId(entityId)) {
        return validationError('Entity id is not valid');
    }
    switch (Number(entityType)) {
        case uploadTypes.INTRO_VIDEO:
        case uploadTypes.INTRO_IMAGE:
            return yield _isIntroExist(user, entityId, entityType);
        case uploadTypes.VIDEO_ATTACHMENT:
            return yield _isAttachmentExist(user, entityId, attachmentTypes.VIDEO);
    }
};

const _isIntroExist = function* (user, introId, type) {
    const intro = yield IntroRepository.getIntro(user, introId, type);
    if (!intro)
        return validationError('Entity is not found');
};

const _isAttachmentExist = function* (user, attachmentId, type) {
    const attachment = yield AttachmentRepository.getAttachment(user, attachmentId, type);
    if (!attachment)
        return validationError('Entity is not found');
};

const _processChunk = function* (uploadingData, chunkPath, data) {
    yield writeToFileSystem(chunkPath, uploadingData.filePath);
    const {isLast} = data;
    if (!Boolean(Number(isLast)))
        return uploadingData.toDTO();
    const entity = yield uploadHandler.handle(saveToEntity.bind(this, data, uploadingData), uploadingData._id.toString());
    return entity.toDTO();
};


const _processLastChunk = function* (user, uploadingData, chunkPath, data) {
    switch (uploadingData.status) {
        case uploadStatus.NOT_UPLOADED:
            return yield _processChunk(uploadingData, chunkPath, data);
        case uploadStatus.STARTED_PROCESSING:
        case uploadStatus.FINISHED_PROCESSING:
            return yield _waitProcessingExecution(user, uploadingData);
    }
};

const _waitProcessingExecution = function* (user, uploadingData) {
    const entity = yield uploadHandler.get(uploadingData._id.toString());
    return entity.toDTO();
};

const writeToFileSystem = function* (chunkPath, destPath) {
    const rs = fs.createReadStream(chunkPath);
    const ws = fs.createWriteStream(destPath, {flags: 'a'});
    rs.pipe(ws);
    yield promisifyWriteStream(ws);
};


const saveToEntity = function* (chunkData, uploadingData) {
    const {entityId, entityType} = chunkData;
    const {filePath} = uploadingData;
    yield _changeProcessingStatus(uploadingData, uploadStatus.STARTED_PROCESSING);
    let entity;
    switch (Number(entityType)) {
        case uploadTypes.INTRO_VIDEO:
            entity = yield _saveIntroVideo(entityId, filePath);
            break;
        case uploadTypes.INTRO_IMAGE:
            entity = yield _saveIntroImage(entityId, filePath);
            break;
        case uploadTypes.VIDEO_ATTACHMENT:
            entity = yield _saveVideoAttachment(entityId, filePath);
            break;
    }
    yield _changeProcessingStatus(uploadingData, uploadStatus.FINISHED_PROCESSING);
    return entity;
};

const _changeProcessingStatus = function* (uploadingData, status) {
    uploadingData.status = status;
    yield uploadingData.save();
};

const _saveIntroVideo = function* (introId, filePath) {
    const introVideoFilePath = yield _rotateAndCropVideo(filePath);
    const thumbnailPath = yield _generateThumbnail(introVideoFilePath);
    const sharingPath = yield _generateMiniThumbnail(thumbnailPath);
    const thumbnailUrl = (FileUtils.getRelativeUrl(thumbnailPath)).replace(new RegExp(/\\/, 'g'), '/');
    const introUrl = (FileUtils.getRelativeUrl(introVideoFilePath)).replace(new RegExp(/\\/, 'g'), '/');
    const sharingUrl = (FileUtils.getRelativeUrl(sharingPath)).replace(new RegExp(/\\/, 'g'), '/');
    return yield IntroRepository.updateIntro(introId, introUrl, thumbnailUrl, null, sharingUrl);
};

const _saveIntroImage = function* (introId, filePath) {
    const introUrl = (FileUtils.getRelativeUrl(filePath)).replace(new RegExp(/\\/, 'g'), '/');
    const sharingPath = yield _generateMiniThumbnail(filePath);
    const sharingUrl = (FileUtils.getRelativeUrl(sharingPath)).replace(new RegExp(/\\/, 'g'), '/');
    return yield IntroRepository.updateIntro(introId, introUrl, null, null, sharingUrl);
};

const _saveVideoAttachment = function* (attachmentId, filePath) {
    const attachFilePath = yield _rotateAndCropVideo(filePath);
    const thumbnailPath = yield _generateThumbnail(attachFilePath);
    const fileThumbnailUrl = (FileUtils.getRelativeUrl(thumbnailPath)).replace(new RegExp(/\\/, 'g'), '/');
    const fileUrl = (FileUtils.getRelativeUrl(attachFilePath)).replace(new RegExp(/\\/, 'g'), '/');
    return yield AttachmentRepository.saveVideoAttach(attachmentId, {fileThumbnailUrl, fileUrl});
};

const _rotateAndCropVideo = function* (filePath) {
    logger.log(`Rotate and crop ${filePath}`);
    const outputFileName = randtoken.generate(32) + VIDEO_FORMAT;
    const outputFilePath = path.join(path.dirname(filePath), outputFileName);
    const command = new RotateAndCropCommand(filePath, outputFilePath);
    ffmpegManager.run(command);
    yield promisifyCommand(command);
    try {
        yield FileUtils.deleteFile(filePath);
    }
    catch (e) {
        logger.error(`Error during deleting after rotate ${filePath}`);
    }

    return outputFilePath;
};

const _generateThumbnail = function* (filePath) {
    logger.log(`Generate thumbnail ${filePath}`);
    const dir = path.dirname(filePath);
    const thumbnailName = path.basename(filePath, path.extname(filePath)) + THUMBNAIL_FORMAT;
    const command = new ThumbnailCommand(filePath, dir, thumbnailName);
    ffmpegManager.run(command);
    yield promisifyCommand(command);
    return path.join(dir, thumbnailName);
};

const _generateMiniThumbnail = function* (filePath) {
    logger.log(`Generate mini thumbnail ${filePath}`);
    const outputFileName = randtoken.generate(32) + MINI_THUMBNAIL_FORMAT;
    const outputFilePath = path.join(path.dirname(filePath), outputFileName);
    const command = new MiniThumbnailCommand(filePath, outputFilePath);
    ffmpegManager.run(command);
    yield promisifyCommand(command);
    return outputFilePath;
};

const cleanUploading = function* (chunkPath, data, isForce) {
    if (chunkPath && chunkPath.length > 0)
        yield FileUtils.deleteTempFile(chunkPath);
    const {dataId} = data;
    if (isForce && Boolean(dataId)) {
        logger.log(`Delete temp file ${dataId.toString()}`);
        yield UploadingDataRepository.deleteUploadingData(dataId);
    }
};

const finishUpload = function* (user, data) {
    const validationError = yield isEntityValid(user, data);
    if (validationError) {
        throw validationError;
    }
    const {dataId} = data;
    const uploadingData = yield UploadingDataRepository.getUploadingData(dataId);
    if (!uploadingData)
        throw notFoundError(404, 'Uploading not found');
    yield UploadingDataRepository.deleteUploadingData(dataId);
};

module.exports = {saveChunk, finishUpload};
