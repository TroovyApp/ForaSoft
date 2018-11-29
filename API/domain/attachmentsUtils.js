'use strict';

const CourseRepository = require('../repositories/CourseRepository');
const AttachmentRepository = require('../repositories/AttachmentRepository');

const validationError = require('../helpers/apiError').validationError;
const validateObjectId = require('../helpers/validators/validateObjectId');

const createAttachment = function* (user, courseId, body) {
    const {params = {}, type} = body;
    if (!validateObjectId(courseId))
        throw validationError('Workshop id is not valid');
    const course = yield CourseRepository.getCourseInfoForOwner(courseId, user._id);
    if (!course)
        throw validationError('Workshop is not found');
    return yield AttachmentRepository.createAttachment(course, type, params);
};

const getAttachments = function* (user, courseId) {
    if (!validateObjectId(courseId))
        throw validationError('Workshop id is not valid');
    const course = yield CourseRepository.getCourseInfoForOwner(courseId, user._id);
    if (!course)
        throw validationError('Workshop is not found');
    return yield AttachmentRepository.getCourseAttachments(courseId);
};

module.exports = {createAttachment, getAttachments};
