'use strict';

const randtoken = require('rand-token');
const path = require('path');

const ffmpegManager = require('./processing/FfmpegManager');
const MiniThumbnailCommand = require('./processing/MiniThumbnailCommand');
const promisifyCommand = require('./processing/promisifyCommand');

const logger = require('../utils/logger');
const FileUtils = require('../helpers/FileUtils');

const FORMAT = '.jpg';

const IntroSchema = require('../schemas/IntroSchema');

function* ensureMiniThumbnailCreated() {
    const intro = yield IntroSchema.find({
        fileSharingUrl: {$exists: false}
    }).exec();

    for (let i = 0; i < intro.length; i++) {
        const relativeImagePath = intro[i].fileThumbnailUrl ? intro[i].fileThumbnailUrl : intro[i].fileUrl;
        if (!relativeImagePath)
            continue;
        const imagePath = FileUtils.resolvePublicPath(relativeImagePath);
        try {
            const sharingPath = yield _generateMiniThumbnail(imagePath);
            intro[i].fileSharingUrl = (FileUtils.getRelativeUrl(sharingPath)).replace(new RegExp(/\\/, 'g'), '/');
        } catch (err) {
            logger.error(`Error during generating thumbnail for ${imagePath}`)
        }
        yield intro[i].save();
    }
}

const _generateMiniThumbnail = function* (filePath) {
    logger.log(`Generate mini thumbnail ${filePath}`);
    const outputFileName = randtoken.generate(32) + FORMAT;
    const outputFilePath = path.join(path.dirname(filePath), outputFileName);
    const command = new MiniThumbnailCommand(filePath, outputFilePath);
    ffmpegManager.run(command);
    yield promisifyCommand(command);
    return outputFilePath;
};

module.exports = {ensureMiniThumbnailCreated};
