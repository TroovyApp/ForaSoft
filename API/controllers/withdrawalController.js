'use strict';

const Router = require('router');
const wrap = require('co').wrap;

const createWithdrawal = require('../domain/withdrawalUtils').createWithdrawal;

const validateWithdrawalParameters = require('../helpers/validators/createWithdrawalValidator');

const apiResponse = require('../helpers/apiResponse');
const auth = require('../helpers/auth');


const router = Router();

/**
 * @apiDefine WithdrawalResponse
 * @apiSuccessExample {json} Withdrawal response:
 * {
 *    "code": 200,
 *   "result": {
 *       "id": "5a017c11ebb31ba2ef81511d",
 *       "user": {
 *           "imageUrl": "",
 *           "name": "Andrew",
 *           "dialCode": "+7",
 *           "phoneNumber": "9999999999",
 *           "credits": 44.72,
 *           "reservedCredits": 2
 *       },
 *       "bankAccountNumber": "234234 234 234 234 234",
 *       "amountCredits": 234,
 *       "createdAt": 1510046737,
 *       "updatedAt": 1510046737,
 *       "isApproved": false,
 *           "currency": "USD"
 *   }
 * }
 * */

/**
 * @api {post} /api/v1/withdrawals
 * @apiVersion 1.0.0
 * @apiName CreateWithdrawal
 * @apiDescription Create withdrawal
 * @apiGroup Withdrawals
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} amountCredits amount of credits for withdrawals
 * @apiParam {String} bankAccountNumber bank account number
 *
 * @apiUse WithdrawalResponse
 * @apiUse AccessDeniedError
 * @apiUse ValidationError
 * @apiUse createWithdrawalWithLessBalance
 * */
router.post('', auth, wrap(function* (req, res) {
    const validationError = yield validateWithdrawalParameters(req.user, req.body);
    if (validationError)
        return res.send(validationError);
    try {
        const withdrawal = yield createWithdrawal(req.user, req.body);

        yield withdrawal.populate('user').execPopulate();
        const withdrawalDTO = withdrawal.toDTO();
        return res.send(apiResponse(withdrawalDTO));
    }
    catch (err) {
        return res.send(err);
    }
}));


module.exports = router;
