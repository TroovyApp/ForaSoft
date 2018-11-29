'use strict';

const CourseRepository = require('../repositories/CourseRepository');
const UserRepository = require('../repositories/UserRepository');

const notFoundError = require('../helpers/apiError').notFoundError;
const validationError = require('../helpers/apiError').validationError;
const serverServiceError = require('../helpers/apiError').serverServiceError;

const validateObjectId = require('../helpers/validators/validateObjectId');

const moneyUtils = require('../utils/money');

const EDIT_USER_BALANCE_TYPES = require('../constants/editUserBalanceTypes');
const {SUBSCRIBE_SERVICE_TAX, SUBSCRIBE_STRIPE_TAX} = require('../constants/appConstants');
const PAYMENT_TYPES = require('../constants/paymentTypes');

const {roundMoney} = require('../utils/money');


module.exports = function* (user, courseId, payTotalResult = 0, transaction = null, paymentType, discount) {
    if (!Boolean(payTotalResult) && discount !== 100)
        throw serverServiceError('Invoice for subscribe was not paid');

    if (!validateObjectId(courseId))
        throw validationError('Workshop id is not valid');

    const course = yield CourseRepository.getCourseForSubscribing(user, courseId);
    if (!course)
        throw notFoundError(404, 'Workshop is not found');

    if (course.creator.isDisabled)
        throw validationError('Sorry, the workshop is temporarily unavailable');

    if (!course)
        throw notFoundError(404, 'Workshop is not found');

    const tax = paymentType === PAYMENT_TYPES.CARD ? SUBSCRIBE_STRIPE_TAX : SUBSCRIBE_SERVICE_TAX;
    const earnings = Number(moneyUtils.getAmountAfterTax(payTotalResult, tax));


    yield UserRepository.editUserBalance(course.creator, earnings, EDIT_USER_BALANCE_TYPES.ADD, transaction);
    const updatedCourse = course.subscribe(user, earnings, course.price);
    return yield Boolean(transaction) ? transaction.update('Course', courseId, updatedCourse) : updatedCourse.save();
};
