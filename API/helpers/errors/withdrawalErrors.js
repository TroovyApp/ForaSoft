'use strict';

const baseError = require('../apiError').baseError;

/**
 * @apiDefine createWithdrawalWithLessBalance
 *
 * @apiError (Error 4xx) createWithdrawalWithLessBalance The amountCredits more than user balance
 *
 * @apiErrorExample {json} The amountCredits more than user balance error response:
 *
 * HTTP/1.1 200 OK
 * {
 *      "code": 401,
 *      "error": {
 *          "message": ""
 *      }
 * }
 * */
const createWithdrawalWithLessBalance = (amountCredits = 0, balance = 0) => {
    const error = {
        balance,
        message: `You haven't enough money on balance`
    };
    return baseError(401, error);
};

module.exports = {
    createWithdrawalWithLessBalance,
};
