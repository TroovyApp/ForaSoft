'use strict';

const Router = require('router');
const wrap = require('co').wrap;

const adminAuth = require('../helpers/adminAuth');

const loginAdmin = require('../domain/adminUtils').loginAdmin;
const logoutAdmin = require('../domain/adminUtils').logoutAdmin;
const disableUser = require('../domain/usersUtils').disableUser;
const deleteCourse = require('../domain/coursesUtils').deleteCourse;
const approveWithdrawal = require('../domain/withdrawalUtils').approveWithdrawal;

const validateAdminAuthParameters = require('../helpers/validators/adminAuth');

const apiResponse = require('../helpers/apiResponse');

const router = Router();

const getUsersList = require('../domain/usersUtils').getUsersList;
const getCoursesList = require('../domain/coursesUtils').getListForAdmin;
const getWithdrawalList = require('../domain/withdrawalUtils').getWithdrawalList;

const ADMIN_CONSTANTS = require('../constants/adminConstants');

/**
 * @apiDefine AdminUserInfo
 * @apiSuccessExample {json} User response:
 * {
 *   "code": 200,
 *   "result": {
 *       "id": "59f875cfd1306245c8381d41",
 *       "dialCode": "+7",
 *       "phoneNumber": "9215565776",
 *       "imageUrl": null,
 *       "name": "Vladislav 988",
 *       "credits": 0,
 *       "updatedAt": "2017-10-31T14:23:28.634Z",
 *       "createdAt": "2017-10-31T13:08:31.808Z",
 *       "isDisabled": true
 *       }
 * }
 * */

/**
 * @apiDefine AdminUsersList
 * @apiSuccessExample {json} User response:
 * {
 *     "code": 200,
 *     "result": {
 *         "items": [
 *             {
 *                 "id": "59d62cbf9701028741260d2c",
 *                 "dialCode": "+7",
 *                 "phoneNumber": "",
 *                 "imageUrl": "",
 *                 "name": "Vladislav",
 *                 "credits": 10.77,
 *                 "createdAt": 1507208383,
 *                 "updatedAt": 1509540945,
 *                 "isDisabled": true
 *             }
 *         ],
 *         "total": 1,
 *         "totalAll": 2011
 *     }
 * }
 * */

/**
 * @apiDefine AdminCoursesList
 * @apiSuccessExample {json} Courses response:
 * {
 *    "code": 200,
 *    "result": {
 *       "items": [
 *           {
 *               "id": "59d487ce7082f76a4fe2d631",
 *               "title": "New courses 2",
 *               "description": "Lorem ipsum dolor",
 *               "courseImageUrl": "/uploads/image-7i6x1mj5evdy7hm9u9dfkfn7b9-1507633777044.jpg",
 *               "courseIntroVideoPreviewUrl": "",
 *               "creatorName": "Vladislav",
 *               "creator": {
 *                   "imageUrl": "",
 *                   "name": "Andrew",
 *                   "dialCode": "+7",
 *                   "phoneNumber": "9999999999",
 *                   "credits": 10.77
 *               },
 *               "webPage": "localhost/courses/59d487ce7082f76a4fe2d631",
 *               "sessions": [],
 *               "status": 1,
 *               "price": 32,
 *               "nearestSessionAt": -1,
 *               "createdAt": 1507100622,
 *               "updatedAt": 1508162644,
 *               "sortBy": 1507100622
 *           }
 *       ],
 *       "total": 1,
 *       "totalAll": 5
 *   }
 * }
 * */

/**
 * @apiDefine AdminWithdrawalInfo
 * @apiSuccessExample {json} Withdrawal response:
 * {
 *    "code": 200,
 *    "result": {
 *        "id": "5a01826094d375a33caad5ec",
 *        "user": {
 *           "imageUrl": "",
 *           "name": "Andrew",
 *           "dialCode": "+7",
 *           "phoneNumber": "9999999999",
 *           "credits": 44.72,
 *           "reservedCredits": 2
 *        },
 *        "bankAccountNumber": "234234 234 234 234 234",
 *        "amountCredits": 290.41,
 *        "createdAt": 1510048352,
 *        "updatedAt": 1510051647,
 *        "isApproved": true
 *    }
 * }
 * */

/**
 * @apiDefine AdminWithdrawalList
 * @apiSuccessExample {json} Withdrawal List response:
 * {
 *    "code": 200,
 *    "result": {
 *        "items": [
 *            {
 *                "id": "5a017c11ebb31ba2ef81511d",
 *                "user": {
 *                   "imageUrl": "",
 *                    "name": "Andrew",
 *                    "dialCode": "+7",
 *                    "phoneNumber": "9999999999",
 *                    "credits": 44.72,
 *                    "reservedCredits": 2
 *                },
 *                "bankAccountNumber": "234234 234 234 234 234",
 *                "amountCredits": 234,
 *                "createdAt": 1510046737,
 *                "updatedAt": 1510046737,
 *                "isApproved": false
 *            }
 *        ],
 *        "total": 1,
 *        "totalAll": 15
 *    }
 * }
 * */

/**
 * @api {post} /api/v1/admin/login
 * @apiVersion 1.0.0
 * @apiName Login
 * @apiDescription Login admin
 * @apiGroup Admin
 *
 * @apiUse EmptySuccessResponse
 * @apiUse ValidationError
 * @apiUse ServerServiceError
 * */
router.post('/login', wrap(function*(req, res) {
    const validationError = validateAdminAuthParameters(req.body);
    if (validationError) {
        res.cookie('isAuth', '0'); // only for informing client
        return res.send(validationError);
    }
    try {
        yield loginAdmin(req);
        res.cookie('isAuth', '1', { expires: new Date(Date.now() + ADMIN_CONSTANTS.SESSION_LIFE_TIME)}); // only for informing client
        return res.send(apiResponse({}));
    }
    catch (err) {
        res.cookie('isAuth', '0'); // only for informing client
        return res.send(err);
    }
}));

/**
 * @api {post} /api/v1/admin/logout
 * @apiVersion 1.0.0
 * @apiName Logout
 * @apiDescription Logout admin
 * @apiGroup Admin
 *
 * @apiUse EmptySuccessResponse
 * @apiUse AccessDeniedError
 * */
router.post('/logout', adminAuth, wrap(function*(req, res) {
    try {
        yield logoutAdmin(req);
        res.cookie('isAuth', '0'); // only for informing client
        return res.send(apiResponse({}));
    }
    catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {get} /api/v1/admin/users/list
 * @apiVersion 1.0.0
 * @apiName ListUsers
 * @apiDescription List users
 * @apiGroup Admin
 *
 * @apiParam {Number} [count=1000] Course count
 * @apiParam {Number} [page=1] Course list's page
 *
 * @apiUse AccessDeniedError
 * @apiUse AdminUsersList
 * */
router.get('/users/list', adminAuth, wrap(function*(req, res) {
    const list = yield getUsersList(req.query);
    return res.send(apiResponse(list));
}));

/**
 * @api {put} /api/v1/admin/user/:userId/disable
 * @apiVersion 1.0.0
 * @apiName UserDisable
 * @apiDescription User disable/enable
 * @apiGroup Admin
 *
 * @apiParam {String} userId user id is provided in URL
 * @apiParam {Boolean} isEnable (if param is '1' then user will be activated )
 *
 * @apiUse AccessDeniedError
 * @apiUse NotFoundError
 * @apiUse ValidationError
 * @apiUse AdminUserInfo
 * */
router.put('/user/:userId/disable', adminAuth, wrap(function*(req, res) {
    try {
        const updated_user = yield disableUser(req);
        return res.send(apiResponse(updated_user.toAdminView()));
    }
    catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {get} /api/v1/admin/courses/list
 * @apiVersion 1.0.0
 * @apiName ListCourse
 * @apiDescription List course
 * @apiGroup Admin
 *
 * @apiParam {Number} [count=1000] Course count
 * @apiParam {Number} [page=1] Course list's page
 *
 * @apiUse AccessDeniedError
 * @apiUse AdminCoursesList
 * */
router.get('/courses/list', adminAuth, wrap(function*(req, res) {
    const list = yield getCoursesList(req.query);
    return res.send(apiResponse(list));
}));

/**
 * @api {delete} /api/v1/admin/courses/:courseId
 * @apiVersion 1.0.0
 * @apiName DeleteCourse
 * @apiDescription Delete course
 * @apiGroup Admin
 *
 * @apiParam {String} courseId Course id is provided in URL
 * @apiParam {Boolean} ignoreSubscribers The number of subscribers will be ignored ( 1 - true, 0 - false )
 * @apiParam {Boolean} ignoreActiveSession Active sessions will be ignored ( 1 - true, 0 - false )
 *
 * @apiUse EmptySuccessResponse
 * @apiUse AccessDeniedError
 * @apiUse ValidationError
 * @apiUse NotFoundError
 * @apiUse deleteCourseWithAnyError
 * */
router.delete('/courses/:courseId', adminAuth, wrap(function*(req, res) {
    const {courseId} = req.params;
    try {
        yield deleteCourse(null, courseId, Boolean(Number(req.body.ignoreSubscribers)), Boolean(Number(req.body.ignoreActiveSession)), true);
        return res.send(apiResponse({}));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {get} /api/v1/admin/withdrawals/list
 * @apiVersion 1.0.0
 * @apiName ListWithdrawal
 * @apiDescription List withdrawal
 * @apiGroup Admin
 *
 * @apiParam {Number} [count=20] withdrawal count
 * @apiParam {Number} [page=1] withdrawal list's page
 *
 * @apiUse AccessDeniedError
 * @apiUse AdminWithdrawalList
 * */
router.get('/withdrawals/list', adminAuth, wrap(function*(req, res) {
    const list = yield getWithdrawalList(req.query);
    return res.send(apiResponse(list));
}));

/**
 * @api {put} /api/v1/admin/withdrawals/:withdrawalId/approve
 * @apiVersion 1.0.0
 * @apiName WithdrawalApprove
 * @apiDescription Withdrawal approve
 * @apiGroup Admin
 *
 * @apiParam {String} withdrawalId withdrawal id is provided in URL
 *
 * @apiUse AccessDeniedError
 * @apiUse NotFoundError
 * @apiUse ValidationError
 * @apiUse AdminWithdrawalInfo
 * @apiUse PayFromBalanceError
 * */
router.put('/withdrawals/:withdrawalId/approve', adminAuth, wrap(function*(req, res) {
    try {
        const updated_withdrawal = yield approveWithdrawal(req);
        return res.send(apiResponse(updated_withdrawal));
    }
    catch (err) {
        return res.send(err);
    }
}));

module.exports = router;
