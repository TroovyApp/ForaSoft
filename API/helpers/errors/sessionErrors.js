'use strict';

const baseError = require('../apiError').baseError;

/**
 * @apiDefine forceFinishedSession
 *
 * @apiError (Error 4xx) forceFinishedSession The course was finished by admin
 *
 * @apiErrorExample {json} Your course was finished by admin error response:
 *
 * HTTP/1.1 200 OK
 * {
 *      "code": 405,
 *      "message": "Your session was finished by Admin"
 * }
 * */
const forceFinishedSession = (message = "Your session was finished by Admin") => {
    return baseError(405, message);
};

module.exports = {
    forceFinishedSession
};
