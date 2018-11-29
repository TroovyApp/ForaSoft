'use strict';

const FileUtils = require('./FileUtils');
const logger = require('../utils/logger');


module.exports = function* (course) {
    try {
        if (course.courseIntroVideoUrl) {
            yield FileUtils.deleteFile(course.courseIntroVideoUrl);
            if(course.courseIntroVideoUrl === course.courseIntroVideoPreviewUrl)
                course.courseIntroVideoPreviewUrl = '';
            course.courseIntroVideoUrl = '';
        }
        if (course.courseIntroVideoPreviewUrl) {
            yield FileUtils.deleteFile(course.courseIntroVideoPreviewUrl);
            course.courseIntroVideoPreviewUrl = '';
        }
        return yield course.save();
    } catch (err) {
        logger.error(err);
    }
};
