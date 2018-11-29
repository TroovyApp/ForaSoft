'use strict';

const CourseRepository = require('../repositories/CourseRepository');
const IntroRepository = require('../repositories/IntroRepository');

const validationError = require('../helpers/apiError').validationError;
const validateObjectId = require('../helpers/validators/validateObjectId');

const createIntro = function* (user, courseId, body) {
    const {order, type} = body;
    if (!validateObjectId(courseId))
        throw validationError('Workshop id is not valid');
    const course = yield CourseRepository.getCourseInfoForOwner(courseId, user._id);
    if (!course)
        throw validationError('Workshop is not found');
    return yield IntroRepository.createIntro(course, type, order);
};

const deleteIntro = function* (user, introId) {
    if (!validateObjectId(introId))
        throw validationError('Intro id is not valid');
    yield user.populate({path: 'courses', match: {intro: {$in: [introId]}}}).execPopulate();
    if (user.courses.length === 0) {
        throw validationError('Intro is not found');
    }
    return yield IntroRepository.deleteIntro(introId);
};

const updateIntroOrder = function* (body) {
    const {orderData = []} = body;
    const list = yield orderData.map(data => {
        const {id, order} = data;
        if (!id || !order || !validateObjectId(id)) {
            return;
        }
        return IntroRepository.updateOrder(id, order);
    });
    return list.filter(intro => {
        return Boolean(intro) && Boolean(intro.fileUrl);
    }).sort((a, b) => {
        if (a.order !== b.order)
            return a.order > b.order ? 1 : -1;
        return a.updatedAt > b.updatedAt ? 1 : -1;
    });
};

module.exports = {createIntro, deleteIntro, updateIntroOrder};
