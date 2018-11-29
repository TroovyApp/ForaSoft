'use strict';

const Router = require('router');
const wrap = require('co').wrap;

const apiResponse = require('../helpers/apiResponse');
const auth = require('../helpers/auth');

const validatePaymentParameters = require('../helpers/validators/PaymentParameters');

const payCourseAndSubscribe = require('../domain/paymentsUtils').payCourseAndSubscribe;
const sendReceipt = require('../domain/paymentsUtils').sendReceipt;
const verifyReceiptAndSubscribe = require('../domain/paymentsUtils').verifyReceiptAndSubscribe;
const saveUserEmail = require('../domain/usersUtils').saveUserEmail;
const checkCoupon = require('../domain/couponsUtils').checkCoupon;
const PAYMENT_TYPES = require('../constants/paymentTypes');

const logger = require('../utils/logger');

const router = Router();


/**
 * @api {post} /api/v1/payments/card/course/:courseId
 * @apiVersion 1.0.0
 * @apiName PaymentsCourse from card
 * @apiDescription PaymentsCourse from card
 * @apiGroup Payments
 *
 * @apiParam {String} [accessToken] If access token provided and it is course owner, API return full course info
 * @apiParam {String} courseId Course id
 * @apiParam {String} price Course price
 * @apiParam {String} stripeToken customer stripe token ( generate on client )
 * @apiParam {String} coupon Coupon
 *
 * @apiUse NotFoundError
 * @apiUse ValidationError
 * */
router.post('/card/course/:courseId', auth, wrap(function* (req, res) {
    try {
        const validationError = yield validatePaymentParameters.paymentFromCardParameters(req.user, req.body);
        if (validationError)
            return res.send(validationError);

        yield payCourseAndSubscribe(
            req.user,
            req.params.courseId,
            Number(req.body.price),
            PAYMENT_TYPES.CARD,
            req.body.stripeToken,
            req.body.coupon
        );

        return res.send(apiResponse({}));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {post} /api/v1/payments/balance/course/:courseId
 * @apiVersion 1.0.0
 * @apiName PaymentsCourse from balance
 * @apiDescription PaymentsCourse from balance
 * @apiGroup Payments
 *
 * @apiParam {String} [accessToken] If access token provided and it is course owner, API return full course info
 * @apiParam {String} courseId Course id
 * @apiParam {String} price Course price
 *
 * @apiUse NotFoundError
 * @apiUse ValidationError
 * @apiUse PayFromBalanceError
 * */
router.post('/balance/course/:courseId', auth, wrap(function* (req, res) {
    try {
        const validationError = yield validatePaymentParameters.paymentFromBalanceParameters(req.user, req.body);
        if (validationError)
            return res.send(validationError);

        yield payCourseAndSubscribe(req.user, req.params.courseId, Number(req.body.price), PAYMENT_TYPES.CREDITS);

        return res.send(apiResponse({}));
    } catch (err) {
        console.log(`Error during pay from balance ${err.stack}`);
        return res.send(err);
    }
}));

/**
 * @api {post} /api/v1/payments/mixed/course/:courseId
 * @apiVersion 1.0.0
 * @apiName PaymentsCourse from card
 * @apiDescription PaymentsCourse from card
 * @apiGroup Payments
 *
 * @apiParam {String} [accessToken] If access token provided and it is course owner, API return full course info
 * @apiParam {String} courseId Course id
 * @apiParam {String} price Course price
 * @apiParam {String} amountFromCard amount of money that the customer wants to pay from the card
 * @apiParam {String} stripeToken customer stripe token ( generate on client )
 *
 * @apiUse NotFoundError
 * @apiUse ValidationError
 * @apiUse PayFromBalanceError
 * */
router.post('/mixed/course/:courseId', auth, wrap(function* (req, res) {
    try {
        const validationError = yield validatePaymentParameters.paymentFromMixedParameters(req.user, req.body);
        if (validationError)
            return res.send(validationError);

        yield payCourseAndSubscribe(req.user, req.params.courseId, Number(req.body.price), PAYMENT_TYPES.MIXED, req.body.stripeToken, null, Number(req.body.amountFromCard));

        return res.send(apiResponse({}));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {post} /api/v1/payments/receipt/:courseId
 * @apiVersion 1.0.0
 * @apiName SendReceipt
 * @apiDescription Send receipt to user after purchase
 * @apiGroup Payments
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} courseId Course id (As part of URL)
 * @apiParam {String} email User's email
 *
 * @apiUse UserResponse
 * @apiUse UserDisabledError
 * @apiUse AccessDeniedError
 * @apiUse NotFoundError
 * */
router.post('/receipt/:courseId', auth, wrap(function* (req, res) {
    const {email} = req.body;
    const {courseId} = req.params;
    try {
        const user = yield saveUserEmail(req.user, email);
        yield sendReceipt(user, email, courseId);

        return res.send(apiResponse(user.toDTO()));
    } catch (err) {
        return res.send(err);
    }
}));


/**
 * @api {post} /api/v1/payments/app/:courseId
 * @apiVersion 1.0.0
 * @apiName VerifyAppleReceipt
 * @apiDescription Verify receipt in Apple and subscribe to course
 * @apiGroup Payments
 *
 * @apiParam {String} accessToken Access Token
 * @apiParam {String} receipt Receipt
 * @apiParam {String} courseId Provided in URL
 * @apiParam {Number} price Price of the course
 *
 * @apiUse NotFoundError
 * @apiUse UserDisabledError
 * @apiUse AccessDeniedError
 * @apiUse ServerServiceError
 *
 * */
router.post('/app/:courseId', auth, wrap(function* (req, res) {
    try {
        const response = yield verifyReceiptAndSubscribe(req.user, req.params.courseId, Number(req.body.price), req.body.receipt);
        console.log(`Response of verify receipt ${response}`);
        return res.send(apiResponse(response));
    } catch (err) {
        console.log(`Error during verify receipt ${err.stack}`);
        return res.send(err);
    }
}));


/**
 * @api {post} /api/v1/payments/coupon
 * @apiVersion 1.0.0
 * @apiName CheckCoupon
 * @apiDescription CheckCoupon
 * @apiGroup Payments
 *
 * @apiParam {String} accessToken Access Token
 * @apiParam {String} coupon Coupon
 *
 * @apiUse NotFoundError
 * @apiUse ServerServiceError
 *
 * */
router.post('/coupon', auth, wrap(function* (req, res) {
    try {
        const response = yield checkCoupon(req.body.coupon);
        return res.send(apiResponse(response));
    } catch (err) {
        console.log(`Error during check coupon ${req.body.coupon}`);
        return res.send(err);
    }
}));

module.exports = router;
