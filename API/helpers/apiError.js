'use strict';

const baseError = (code, error) => {
    return {
        code,
        error
    };
};

/**
 * @apiDefine ValidationError
 *
 * @apiError (Error 4xx) ValidationError Some request parameters are invalid. See error description for more information.
 *
 * @apiErrorExample {json} Validation error response:
 *
 * HTTP/1.1 200 OK
 * {
 *      "code": 400,
 *      "error": "Error description"
 * }
 * */
const validationError = (error) => {
    return {
        code: 400,
        error
    };
};

/**
 * @apiDefine UserDisabledError
 *
 * @apiError (Error 4xx) UserDisabledError Support disabled account
 *
 * @apiErrorExample {json} User disabled error response:
 *
 * HTTP/1.1 200 OK
 * {
 *      "code": 405,
 *      "error": "Your account is disabled by support"
 * }
 * */
const userDisabledError = () => {
    return {
        code: 405,
        error: 'Your account is disabled by support'
    };
};

/**
 * @apiDefine AccessDeniedError
 *
 * @apiError (Error 4xx) AccessDeniedError Access denied
 *
 * @apiErrorExample {json} Access denied error response:
 *
 * HTTP/1.1 200 OK
 * {
 *      "code": 403,
 *      "error": "Access denied"
 * }
 * */
const accessDeniedError = () => {
    return {
        code: 403,
        error: 'Access denied'
    };
};

/**
 * @apiDefine NotConfirmedAccountError
 *
 * @apiError (Error 4xx) NotConfirmedAccountError Account is not confirmed
 *
 * @apiErrorExample {json} Not confirmed account error response:
 *
 * HTTP/1.1 200 OK
 * {
 *      "code": 401,
 *      "error": "Phone number is not verified"
 * }
 * */
const accountIsNotVerifiedError = () => {
    return {
        code: 401,
        error: 'Phone number is not verified'
    };
};

/**
 * @apiDefine NotFoundError
 *
 * @apiError (Error 4xx) NotFoundError Not Found Error. See error description for more information.
 *
 * @apiErrorExample {json} Not found error response:
 *
 * HTTP/1.1 200 OK
 * {
 *      "code": 404,
 *      "error": "Error description"
 * }
 * */
const notFoundError = (code, error) => {
    return {code, error};
};

 /**
 * @apiDefine PayFromBalanceError
 *
 * @apiError (Error 4xx) PayFromBalanceError The balance is less than the invoice
 *
 * @apiErrorExample {json} The balance is less than the invoice error response:
 *
 * HTTP/1.1 200 OK
 * {
 *      "code": 400,
 *      "error": {
 *          "credits": 1000
 *      }
 * }
 * */
const payFromBalanceError = (credits, amount = 0) => {
    return {
        code: 400,
        error: {
            credits
        }
    };
};

/**
 * @apiDefine ServerServiceError
 *
 * @apiError (Error 5xx) ServerServiceError Some service server error. For example, Twilio errors are returned here with error description.
 *
 * @apiErrorExample {json} Server service error response:
 *
 * HTTP/1.1 200 OK
 * {
 *      "code": 502,
 *      "error": "Error description"
 * }
 * */
const serverServiceError = (error) => {
    return {
        code: 502,
        error
    }
};

const stripePaymentError = (error)=>{
    return {
        code: 402,
        error
    };
};

module.exports = {
    baseError,
    validationError,
    userDisabledError,
    accountIsNotVerifiedError,
    notFoundError,
    serverServiceError,
    accessDeniedError,
    payFromBalanceError,
    stripePaymentError
};
