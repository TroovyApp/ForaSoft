'use strict';

const moment = require('moment');
const iap = require('in-app-purchase');

const Transaction = require('../utils/Transaction');

const UserRepository = require('../repositories/UserRepository');
const CourseRepository = require('../repositories/CourseRepository');

const validateObjectId = require('../helpers/validators/validateObjectId');

const notFoundError = require('../helpers/apiError').notFoundError;
const validationError = require('../helpers/apiError').validationError;

const payFromBalance = require('../helpers/pay').payFromBalance;
const payFromCard = require('../helpers/pay').payFromCard;
const payFromMixed = require('../helpers/pay').payFromMixed;
const roundMoney = require('../utils/money').roundMoney;
const checkCoupon = require('../domain/couponsUtils').checkCoupon;
const {baseError, serverServiceError} = require('../helpers/apiError');

const subscribeCourse = require('../helpers/subscribeCourse');

const {sendMail} = require('../helpers/email/emailGateway');
const ReceiptEmailTemplate = require('../helpers/email/templates/ReceiptEmailTemplate');
const config = require('../config');

const PAYMENT_TYPES = require('../constants/paymentTypes');


const payCourse = function* (user, courseId, price, paymentType, stripeToken = null, amountFromCard = NaN, transaction, discount) {
    if (!validateObjectId(courseId))
        throw validationError('Workshop id is not valid');
    const course = yield CourseRepository.getCourseForSubscribing(user, courseId);
    if (!course)
        throw notFoundError(404, 'Workshop for subscribe not found');

    switch (paymentType) {
        case PAYMENT_TYPES.CREDITS:
            return yield payFromBalance(user, Number(price), transaction);
            break;
        case PAYMENT_TYPES.CARD: {
            const description = `Subscription to the workshop '${course.title}'`;
            const metadata = {currency: course.currency};
            return yield payFromCard(user, Number(price), stripeToken, description, metadata, discount);
        }
            break;
        case PAYMENT_TYPES.MIXED: {
            const description = `Subscription to the workshop '${course.title}'`;
            const metadata = {currency: course.currency};
            return yield payFromMixed(user, Number(price), stripeToken, description, metadata, amountFromCard, transaction);
        }
            break;
        default:
            throw new Error('Payment method is not implementation for payCourse');
    }
};

const payCourseAndSubscribe = function* (user, courseId, price, paymentType, stripeToken = null, couponId = null, amountFromCard = NaN) {
    const transaction = new Transaction();
    console.log('payCourseAndSubscribe');
    try {
        const coupon = yield checkCoupon(couponId);
        const discount = coupon ? coupon.percent_off : 0;

        const course = yield CourseRepository.getCourseForSubscribing(user, courseId);

        const priceWithDiscount = discount
            ? roundMoney((course.price * 100 - course.price * discount) / 100)
            : course.price;

        yield subscribeCourse(user, courseId, priceWithDiscount, transaction, paymentType, discount);
        yield payCourse(user, courseId, priceWithDiscount, paymentType, stripeToken, amountFromCard, transaction, discount);
        yield savePaymentDetails(user, paymentType, courseId, priceWithDiscount);
        yield transaction.run();
    }
    catch (err) {
        yield transaction.rollback();
        throw err;
    }
};

const sendReceipt = function* (user, email, courseId) {
    const course = yield CourseRepository.findCourse(courseId);
    if (!course)
        throw notFoundError(404, 'Workshop is not found');

    yield course.populate('creator').execPopulate();
    const paymentDetails = user.lastPaymentDetails || {};
    const total = new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: course.currency
    }).format(paymentDetails.total || 0);
    const options = {
        orderDate: moment().format('DD MMM YYYY'),
        userName: user.name,
        courseName: course.title,
        authorName: course.creator.name,
        total,
        paymentMethod: getPaymentMethodByType(paymentDetails.method)
    };

    console.log(`Send email ${email} ${JSON.stringify(options)}`);
    try {
        yield sendMail({
            from: config.mailFrom,
            to: email,
            subject: 'Troovy workshop order',
            html: ReceiptEmailTemplate.render(options)
        });
        console.log(`Email sent`);
    } catch (err) {
        console.log(`Error during sending receipt ${err.stack}`);
    }
};

function getPaymentMethodByType(type) {
    switch (type) {
        case PAYMENT_TYPES.CREDITS:
            return 'Troovy App balance';
        case PAYMENT_TYPES.IN_APP:
            return 'Apple Wallet';
        case PAYMENT_TYPES.CARD:
            return 'Bank card';
        default:
            return 'Troovy App balance';
    }
}

const verifyReceiptAndSubscribe = function* (user, courseId, price, receipt) {
    let response;
    try {
        response = yield promisifyIapValidate(receipt);
    } catch (err) {
        throw serverServiceError(err);
    }

    if (response.status !== 0) {
        return response;
    }
    yield subscribeCourse(user, courseId, price, null, PAYMENT_TYPES.IN_APP);
    yield savePaymentDetails(user, PAYMENT_TYPES.IN_APP, courseId);
    return response;
};

const promisifyIapValidate = function (receipt) {
    return new Promise(function (resolve, reject) {
        iap.validate(receipt, function (err, response) {
            if (err)
                return reject(err);
            return resolve(response);
        });
    });
};

const savePaymentDetails = function* (user, method, courseId, totalWithDiscount) {
    const course = yield CourseRepository.findCourse(courseId);
    user.lastPaymentDetails = {
        method,
        courseName: course.title,
        total: totalWithDiscount
    };
    user.markModified('lastPaymentDetails');
    yield user.save();
};

module.exports = {
    payCourse,
    payCourseAndSubscribe,
    sendReceipt,
    verifyReceiptAndSubscribe
};
