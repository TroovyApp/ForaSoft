'use strict';

const baseError = require('../apiError').baseError;

/**
 * @apiDefine deleteCourseWithActiveSessionError
 *
 * @apiError (Error 4xx) deleteCourseWithActiveSessionError The course have an active session
 *
 * @apiErrorExample {json} The course have an active session error response:
 *
 * HTTP/1.1 200 OK
 * {
 *      "code": 401,
 *      "error": {
 *          "message": "You have an active session in the course. Please, finish the session to be able to delete a course"
 *      }
 * }
 * */
const deleteCourseWithActiveSessionError = (message = "You have an active session in the workshop. Please, finish the session to be able to delete a workshop") => {
    const error = {
        message
    };
    return baseError(401, error);
};

/**
 * @apiDefine deleteCourseWithSubscribersError
 *
 * @apiError (Error 4xx) deleteCourseWithSubscribersError The course have an subscribers
 *
 * @apiErrorExample {json} The course have an 2 subscribers error response:
 *
 * HTTP/1.1 200 OK
 * {
 *      "code": 402,
 *      "error": {
 *          "subscribers" : 2,
 *          "message": "Your course has 2 subscribers. Are you sure you want to delete a course?"
 *      }
 * }
 * */
const deleteCourseWithSubscribersError = (subscribers, forAdmin = false) => {
    const error = {
        subscribers,
        message: forAdmin ?
            `This workshop has ${Number(subscribers)} subscribers. Are you sure you want to delete a workshop?` :
            `Your workshop has ${Number(subscribers)} subscribers. Are you sure you want to delete a workshop?`
    };
    return baseError(402, error);
};

/**
 * @apiDefine deleteCourseWithAnyError
 *
 * @apiError (Error 4xx) deleteCourseWithAnyError The course have an subscribers or an active session
 *
 * @apiErrorExample {json} The course have an 2 subscribers and active session error response for admin:
 *
 * HTTP/1.1 200 OK
 * {
 *      "code": 403,
 *      "error": {
 *          "message": "This course has 2 subscribers and active session. You want to delete the course?"
 *      }
 * }
 * */
const deleteCourseWithAnyError = (errors) => {
    let errorMessage = errors.reduce((prev, error, key) => {
        return `${prev} ${error}`;
    }, '');
    errorMessage += ' You want to delete the workshop?';
    const error = {
        message: errorMessage
    };
    return baseError(403, error);
};

module.exports = {
    deleteCourseWithActiveSessionError,
    deleteCourseWithSubscribersError,
    deleteCourseWithAnyError
};
