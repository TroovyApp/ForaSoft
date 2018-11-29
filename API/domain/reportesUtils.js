'use strict';

const ReportRepository = require('../repositories/ReportRepository');

const REPORT_ENTITY_TYPES = require('../constants/reportEntityTypes');
const coursesUtils = require('./coursesUtils');
const usersUtils = require('./usersUtils');


const createReport = function* (user, body) {
    const {targetId, targetType = REPORT_ENTITY_TYPES.NONE, reason} = body;
    const report = yield ReportRepository.createReport(user, reason, targetId, Number(targetType) );
    switch (Number(targetType)) {
        case REPORT_ENTITY_TYPES.COURSE :
            const course = yield coursesUtils.findCourse(user, {courseId: targetId}, false);
            if(course && Boolean(course.creator)){
                yield usersUtils.reportUserById(course.creator.id);
            }
            break;
    }

    return report;
};

module.exports = {
    createReport
};
