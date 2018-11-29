'use strict';

const Router = require('router');
const wrap = require('co').wrap;

const verifyPhoneNumber = require('../domain/usersUtils').verifyPhoneNumber;
const confirmPhoneNumber = require('../domain/usersUtils').confirmPhoneNumber;
const registerUser = require('../domain/usersUtils').registerUser;
const editUser = require('../domain/usersUtils').editUser;
const logoutUser = require('../domain/usersUtils').logoutUser;
const findUsersById = require('../domain/usersUtils').findUsersById;
const saveUserDeviceData = require('../domain/usersUtils').saveUserDeviceData;

const validateVerificationParameters = require('../helpers/validators/verifyValidator');
const validateConfirmationParameters = require('../helpers/validators/confirmValidator');
const validateRegistrationParameters = require('../helpers/validators/registerValidator');

const apiResponse = require('../helpers/apiResponse');
const imageUpload = require('../helpers/imageUploader');
const auth = require('../helpers/auth');
const parseImageUrlFromFile = require('../utils/parseImageUrlFromFile');


const router = Router();

/**
 * @apiDefine UserResponse
 * @apiSuccessExample {json} User response:
 * {
 *  "code": 200,
 *  "result": {
 *      "id": "599a97b42f6c7f329c6e5b43",
 *      "dialCode": "+7",
 *      "phoneNumber": "1111111111",
 *      "accessToken": "0ja6COFWmkjVCcpf7agRBAJeohoCLYb2",
 *      "imageUrl": "/uploads/image-963o9t506w8hnf8fvo6tuik9-1503303601422.jpg",
 *      "name": "Vladislav",
 *      "credits": "0",
 *      "email": "address@site.com",
 *      "createdAt": 1503305295,
 *      "updatedAt": 1503305353,
 *           "currency": "USD"
 *  }
 * }
 * */

/**
 * @apiDefine UserInfo
 * @apiSuccessExample {json} User info:
 * {
 *  "code": 200,
 *  "result": {
 *      "dialCode": "+7",
 *      "phoneNumber": "1111111111",
 *      "imageUrl": "/uploads/image-963o9t506w8hnf8fvo6tuik9-1503303601422.jpg",
 *      "name": "Vladislav",
 *      "credits": "0",
 *      "email": "address@site.com",
 *           "currency": "USD"
 *  }
 * }
 * */

/**
 * @apiDefine AppConfigurationResponse
 * @apiSuccessExample {json} App configuration:
 * {
 *  "code": 200,
 *  "result": {
 *      "subscribeServiceTax": "0.3",
 *      "payoutServiceTax": "0",
 *      "minimumPayoutAmount": "0"
 *  }
 * }
 * */

/**
 * @apiDefine UserList
 * @apiSuccessExample {json} User response:
 * {
 *  "code": 200,
 *  "result": [{
 *      "id": "599a97b42f6c7f329c6e5b43",
 *      "imageUrl": "/uploads/image-963o9t506w8hnf8fvo6tuik9-1503303601422.jpg",
 *      "name": "Vladislav",
 *      "email": "address@site.com",
 *           "currency": "USD"
 *  }]
 * }
 * */

/**
 * @api {post} /api/v1/users/verify
 * @apiVersion 1.0.0
 * @apiName RequestConfirmation
 * @apiDescription Request confirmation code
 * @apiGroup Users
 *
 * @apiParam {String} appGeneratedToken App generated token
 * @apiParam {String} dialCode
 * @apiParam {String} phoneNumber
 *
 * @apiUse EmptySuccessResponse
 * @apiUse ValidationError
 * @apiUse ServerServiceError
 * @apiUse UserDisabledError
 * */
router.post('/verify', wrap(function* (req, res) {
    const validationError = validateVerificationParameters(req.body);
    if (validationError)
        return res.send(validationError);

    try {
        yield verifyPhoneNumber(req.body);
        return res.send(apiResponse({}));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {post} /api/v1/users/confirm
 * @apiVersion 1.0.0
 * @apiName Confirmation
 * @apiDescription Confirm code. If user has already registered, api returns User Response.
 * @apiGroup Users
 *
 * @apiParam {String} appGeneratedToken App generated token
 * @apiParam {String} confirmationCode
 *
 * @apiUse EmptySuccessResponse
 * @apiUse UserResponse
 * @apiUse ValidationError
 * @apiUse NotFoundError
 * @apiUse UserDisabledError
 * */
router.post('/confirm', wrap(function* (req, res) {
    const validationError = validateConfirmationParameters(req.body);
    if (validationError)
        return res.send(validationError);

    try {
        const user = yield confirmPhoneNumber(req.body);
        return res.send(apiResponse(user));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {post} /api/v1/users
 * @apiVersion 1.0.0
 * @apiName Registration
 * @apiDescription Register user
 * @apiGroup Users
 *
 * @apiParam {String} appGeneratedToken App generated token
 * @apiParam {String} dialCode
 * @apiParam {String} phoneNumber
 * @apiParam {String} name
 * @apiParam {File} [image] Profile image (file)
 *
 * @apiUse UserResponse
 * @apiUse ValidationError
 * @apiUse NotConfirmedAccountError
 * */
router.post('', imageUpload('image'), wrap(function* (req, res) {
    const validationError = validateRegistrationParameters(req.body);
    if (validationError)
        return res.send(validationError);
    const imageUrl = parseImageUrlFromFile(req.file);

    try {
        const user = yield registerUser(req.body, imageUrl);
        return res.send(apiResponse(user));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {put} /api/v1/users/:courseId
 * @apiVersion 1.0.0
 * @apiName EditUser
 * @apiDescription Edit user
 * @apiGroup Users
 *
 * @apiParam {String} appGeneratedToken App generated token
 * @apiParam {String} [name]
 * @apiParam {String} [email]
 * @apiParam {File} [image] Profile image (file)
 * @apiParam {Boolean} [isUserAvatarShouldDelete=false] If need to delete user's avatar image
 *
 * @apiUse AccessDeniedError
 * @apiUse UserResponse
 * @apiUse NotFoundError
 * */
router.put('/:userId', auth, imageUpload('image'), wrap(function* (req, res) {
    try {
        const imageUrl = req.file ? parseImageUrlFromFile(req.file) : null;
        const user = yield editUser(req.user, req.body, imageUrl, Boolean(Number(req.body.isUserAvatarShouldDelete)));
        return res.send(apiResponse(user.toDTO()));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {post} /api/v1/users/logout
 * @apiVersion 1.0.0
 * @apiName Logout
 * @apiDescription Logout user
 * @apiGroup Users
 *
 * @apiParam {String} accessToken Access token
 *
 * @apiUse EmptySuccessResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * */
router.post('/logout', auth, wrap(function* (req, res) {
    yield logoutUser(req.user, req.query.accessToken);
    return res.send(apiResponse({}));
}));

/**
 * @api {get} /api/v1/users
 * @apiVersion 1.0.0
 * @apiName UserInfo
 * @apiDescription Get own profile
 * @apiGroup Users
 *
 * @apiParam {String} accessToken Access token
 *
 * @apiUse UserInfo
 * @apiUse UserDisabledError
 * @apiUse AccessDeniedError
 * */
router.get('', auth, wrap(function* (req, res) {
    return res.send(apiResponse(req.user.toInfo()));
}));

/**
 * @api {post} /api/v1/users/all
 * @apiVersion 1.0.0
 * @apiName UsersByIds
 * @apiDescription Find users by id
 * @apiGroup Users
 *
 * @apiParam {Array} ids Users' id
 *
 * @apiUse UserList
 * @apiUse UserDisabledError
 * */
router.post('/all', auth, wrap(function* (req, res) {
    const list = yield findUsersById(req.body);
    return res.send(apiResponse(list));
}));

/**
 * @api {post} /api/v1/users/config
 * @apiVersion 1.0.0
 * @apiName UserAppConfig
 * @apiDescription Method for transfer user device data and app configuration
 * @apiGroup Users
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} [pushToken] APN token
 * @apiParam {Number} [timezone] Timezone offset from UTC in seconds. For example, timezone offset for UTC+3 (Europe/Moscow) is 10800.
 *
 * @apiUse AppConfigurationResponse
 * @apiUse UserDisabledError
 * @apiUse AccessDeniedError
 * @apiUse ValidationError
 * */
router.post('/config', auth, wrap(function* (req, res) {
    const appConfig = yield saveUserDeviceData(req.user, req.query.accessToken, req.body);
    return res.send(apiResponse(appConfig));
}));




module.exports = router;
