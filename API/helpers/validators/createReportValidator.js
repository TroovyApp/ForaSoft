'use strict';

const validationError = require('../apiError').validationError;

const REPORT_ENTITY_TYPES = require('../../constants/reportEntityTypes');

const CourseRepository = require('../../repositories/CourseRepository');
const validateObjectId = require('./validateObjectId');
const ObjectId = require('mongodb').ObjectID;


const validateTargetExists = function* (targetId, targetType) {
    switch (Number(targetType)){
        case REPORT_ENTITY_TYPES.COURSE :
            const course = yield CourseRepository.findCourse(ObjectId(targetId));
            return Boolean(course);
            break;
        default:
            return false;
    }
};

module.exports = function*(user, body) {
    const error = {};
    if (!body.targetId){
        error.targetId = 'targetId is required';
        return validationError(error);
    }
    if(!validateObjectId(body.targetId)){
        error.targetId = 'targetId id is not valid';
        return validationError(error);
    }
    if (!body.targetType || body.targetType === REPORT_ENTITY_TYPES.NONE)
        error.targetType = 'targetType is required';
    if(!(yield validateTargetExists(body.targetId, body.targetType)))
        error.target = 'target of report is not found';
    if (!body.reason)
        error.reason = 'reason is required';
    if (Object.keys(error).length > 0)
        return validationError(error);
};
