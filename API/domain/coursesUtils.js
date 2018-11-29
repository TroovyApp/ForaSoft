'use strict';

const CourseRepository = require('../repositories/CourseRepository');
const UserRepository = require('../repositories/UserRepository');

const notFoundError = require('../helpers/apiError').notFoundError;
const validationError = require('../helpers/apiError').validationError;
const courseErrors = require('../helpers/errors/courseErrors');

const validateObjectId = require('../helpers/validators/validateObjectId');
const parseQualities = require('../helpers/qualitiesParser');
const FileUtils = require('../helpers/FileUtils');
const deleteIntroVideoHelper = require('../helpers/deleteIntroVideo');
const deleteCourseImageHelper = require('../helpers/deleteCourseImage');
const deleteCourseIntroHelper = require('../helpers/deleteCourseIntro');
const {finishSessionHelper} = require('../helpers/LiveSessionsHelpers');
const subscribeCourseHelper = require('../helpers/subscribeCourse');

const COURSE_TIME_STATUS = require('../constants/timeStatus');

const DEFAULT_COURSE_COUNT = 1000;
const DEFAULT_COURSE_PAGE = 1;

const COURSES_SORT_MODS = require('../constants/courseSortMods');
const DEFAULT_COURSES_SORT_MOD = COURSES_SORT_MODS.COURSE_CREATE;

const createCourse = function* (user, body, imageUrl) {
    const {title, description, price, status = 0, tier, currency} = body;
    const course = yield CourseRepository.createCourse(user, title, description, price, tier, Number(status), imageUrl, currency);
    yield course.populate('intro').execPopulate();
    yield UserRepository.addCourse(user, course);
    return course;
};

const findCourse = function* (user, params, format = true) {
    const {courseId} = params;
    if (!Boolean(user))
        return yield findCourseForNotOwner(user, courseId, format);
    return yield findCourseForOwner(user, courseId, format);
};

const findCourseForOwner = function* (user, courseId, format = true) {
    if (!validateObjectId(courseId))
        throw validationError('Workshop id is not valid');
    let course = yield CourseRepository.getCourseInfoForOwner(courseId, user._id.toString());
    if (!course)
        return yield findCourseForNotOwner(user, courseId, format);
    // throw notFoundError(404, 'Course is not found');
    if (format)
        return course.toDTO(user);
    return course;
};

const findCourseForNotOwner = function* (user, courseId, format = true) {
    if (!validateObjectId(courseId))
        throw validationError('Workshop id is not valid');
    const course = yield CourseRepository.getCourseInfoForNotOwner(courseId);
    if (!course)
        throw notFoundError(404, 'Workshop is not found');
    if (format)
        return course.toNotOwnerDTO(user);
    return course;
};

const getList = function* (user, query) {
    const {
        userId = '',
        count = DEFAULT_COURSE_COUNT,
        page = DEFAULT_COURSE_PAGE,
        sortMod = DEFAULT_COURSES_SORT_MOD,
        withoutMyCourses = false,
        subscribed = false
    } = query;
    if (Boolean(userId) && !validateObjectId(userId))
        throw validationError('UserId is not valid');
    const list = yield CourseRepository.getCourseList(user, count, page, Boolean(Number(withoutMyCourses)), Boolean(Number(subscribed)), userId);
    return list.map(course => {
        return course.toListDTO(sortMod);
    }).sort((a, b) => {
        return a.sortBy - b.sortBy;
    });
};

const getListForAdmin = function* (query) {
    const {
        count = DEFAULT_COURSE_COUNT,
        page = DEFAULT_COURSE_PAGE,
        sortMod = COURSES_SORT_MODS.COURSE_TITLE
    } = query;
    let list = yield CourseRepository.getCourseListForAdmin(count, page);
    list = list.map(course => course.toAdminDTO(sortMod))
        .sort((a, b) => {
            return a.sortBy - b.sortBy;
        });

    const totalAll = yield CourseRepository.getCoursesCount();
    const result = {
        items: list,
        total: list.length,
        totalAll
    };

    return result;
};

const findCoursesById = function* (user, body) {
    const {ids = []} = body;
    const searchIds = ids.filter(id => {
        return validateObjectId(id);
    });
    const courses = yield CourseRepository.getCoursesByIds(searchIds);
    return courses.map(course => {
        return course.toShortDTO(user);
    });
};

const editCourse = function* (user, courseId, body, imageUrl) {
    try {
        if (!validateObjectId(courseId))
            throw validationError('Workshop id is not valid');
        const course = yield CourseRepository.getCourseForEditing(user, courseId);
        if (!course)
            throw notFoundError(404, 'Workshop is not found');
        if (imageUrl) {
            yield deleteCourseIntroHelper(course);
        }
        if (Boolean(Number(body.isCourseImageShouldDelete))) {
            yield deleteCourseImage(course);
        }
        if (Boolean(Number(body.isCourseIntroVideoShouldDelete))) {
            yield deleteIntroVideo(course);
        }
        const courseQualities = parseCourseQualities(body, imageUrl);
        return yield CourseRepository.updateCourse(course, courseQualities);
    }
    catch (err) {
        try {
            if (imageUrl)
                yield FileUtils.deleteFile(imageUrl);
        }
        catch (err) {
            throw err;
        }
        throw err;
    }

};

const deleteCourseImage = function* (course) {
    return yield deleteCourseImageHelper(course);
};

const deleteIntroVideo = function* (course) {
    return yield deleteIntroVideoHelper(course);
};

const COURSE_FIELDS = ['title', 'description', 'price', 'tier', 'status'];

const parseCourseQualities = function (body, imageUrl) {
    const qualities = parseQualities(body, COURSE_FIELDS);
    if (imageUrl) {
        qualities.courseImageUrl = imageUrl;
    }
    return qualities;
};

const findCourseSessions = function* (courseId) {
    if (!validateObjectId(courseId))
        throw validationError('Workshop id is not valid');
    const course = yield CourseRepository.findCourse(courseId);
    if (!course)
        throw notFoundError(404, 'Workshop is not found');
    yield course.populate('sessions').execPopulate();
    return course.sessions;
};

const subscribeCourse = function* (user, courseId, payResult = 0, transaction, paymentType) {
    return yield subscribeCourseHelper(user, courseId, payResult, transaction, paymentType);
};

const findUpcomingSessions = function* (user) {
    const sessions = yield CourseRepository.findUpcomingSessions(user);
    return sessions.sort((sessionA, sessionB) => {
        if (sessionA.startAt < sessionB.startAt)
            return -1;
        if (sessionA.startAt > sessionB.startAt)
            return 1;
        return 0;
    });
};

const deleteCourse = function* (user, courseId, ignoreSubscribers = false, ignoreActiveSession = false, asAdmin = false) {
    const course = yield CourseRepository.findCourseForRemoving(courseId, user);
    let errors = [];

    if (!course)
        throw notFoundError(404, 'Workshop is not found');

    const anySessionsStarted = yield CourseRepository.getSomeUpcomingSessionTimeStatus(courseId, COURSE_TIME_STATUS.STARTED);
    if (anySessionsStarted && !ignoreActiveSession) {
        if (asAdmin)
            errors.push("This workshop has an active session.");
        else
            throw courseErrors.deleteCourseWithActiveSessionError("You have an active session in the workshop. Please, finish the session to be able to delete a workshop");
    }

    const countSubscribers = course.subscribers.length;
    if (!ignoreSubscribers && countSubscribers > 0) {
        if (asAdmin)
            errors.push(`This workshop has ${Number(countSubscribers)} subscribers.`);
        else
            throw courseErrors.deleteCourseWithSubscribersError(countSubscribers);
    }

    if (asAdmin && errors.length > 0) {
        throw courseErrors.deleteCourseWithAnyError(errors);
    }

    if (ignoreActiveSession && anySessionsStarted) {
        const sessions = course.sessions;
        yield sessions.map((session) => {
            return finishSessionHelper(course.creator, session.id, true);
        });
    }

    yield deleteCourseIntroHelper(course);

    return yield CourseRepository.deleteCourse(user, course.id);
};

module.exports = {
    createCourse,
    findCourse,
    getList,
    getListForAdmin,
    findCoursesById,
    findCourseForOwner,
    editCourse,
    findCourseSessions,
    subscribeCourse,
    findUpcomingSessions,
    deleteCourse
};
