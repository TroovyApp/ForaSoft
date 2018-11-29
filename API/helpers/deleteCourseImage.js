'use strict';

const FileUtils = require('./FileUtils');
const logger = require('../utils/logger');


module.exports = function* (course) {
    try {
        if (!course.courseImageUrl || course.courseImageUrl.length === 0)
            return Promise.resolve();
        yield FileUtils.deleteFile(course.courseImageUrl);

        course.courseImageUrl = '';
        return yield course.save();
    } catch (err) {
        logger.error(err);
    }
};
