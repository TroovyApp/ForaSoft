'use strict';

const Router = require('router');
const wrap = require('co').wrap;

const imageUpload = require('../helpers/imageUploader');
const apiResponse = require('../helpers/apiResponse');
const parseImageUrlFromFile = require('../utils/parseImageUrlFromFile');
const auth = require('../helpers/auth');
const softAuth = require('../helpers/softAuth');

const validateCreateCourseParameters = require('../helpers/validators/createCourseValidator');

const createCourse = require('../domain/coursesUtils').createCourse;
const findCourse = require('../domain/coursesUtils').findCourse;
const getList = require('../domain/coursesUtils').getList;
const findCoursesById = require('../domain/coursesUtils').findCoursesById;
const editCourse = require('../domain/coursesUtils').editCourse;
const findCourseSessions = require('../domain/coursesUtils').findCourseSessions;
const subscribeCourse = require('../domain/coursesUtils').subscribeCourse;
const deleteCourse = require('../domain/coursesUtils').deleteCourse;

const createSession = require('../domain/sessionsUtils').createSession;
const {DEFAULT_CURRENCY} = require('../constants/appConstants');

const logger = require('../utils/logger');

const router = Router();

/**
 * @apiDefine CourseResponse
 * @apiSuccessExample {json} Course response:
 * {
 *   "code": 200,
 *   "result": {
 *      "id": "59f99873aec92b12848d39ce",
 *      "title": "asd",
 *      "description": "asd",
 *      "status": 1,
 *      "courseImageUrl": "",
 *      "courseIntroVideoUrl": "/uploads/5a2667467bdece1a84ae7567/SWxBVgg3aGOTeefvrQKYoBrFovzgc83b.mp4",
 *      "courseIntroVideoPreviewUrl": "/uploads/5a2667467bdece1a84ae7567/SWxBVgg3aGOTeefvrQKYoBrFovzgc83b.png",
 *      "courseImageSharingUrl": "/uploads/5a2667467bdece1a84ae7567/SWxBVgg3aGOTeefvrQKYoBrFovzgc83b.png",
 *      "intro": [
 *          {
 *              "id": "5a2666ea7bdece1a84ae7565",
 *              "type": 3,
 *              "fileUrl": "/uploads/5a2666ea7bdece1a84ae7565/OP5JhJ21sQw7okF67vZsWt6AHbInKFN3.jpg",
 *              "order": 1,
 *              "createdAt": 1512466154,
 *              "updatedAt": 1512466178
 *          },
 *          {
 *              "id": "5a2667467bdece1a84ae7567",
 *              "type": 1,
 *              "fileUrl": "/uploads/5a2667467bdece1a84ae7567/SWxBVgg3aGOTeefvrQKYoBrFovzgc83b.mp4",
 *              "fileThumbnailUrl": "/uploads/5a2667467bdece1a84ae7567/SWxBVgg3aGOTeefvrQKYoBrFovzgc83b.png",
 *              "order": 2,
 *              "createdAt": 1512466246,
 *              "updatedAt": 1512466299
 *          }
 *      ],
 *      "price": 0,
 *      "tier": "",
 *      "creatorId": "59e4799c9079d2638e46f305",
 *      "creatorName": "Andrey",
 *      "sessions": [
 *          {
 *              "id": "59f99873aec92b12848d39cf",
 *              "title": "asd",
 *              "description": "asd",
 *              "duration": 30,
 *              "courseId": "59f99873aec92b12848d39ce",
 *              "timeStatus": 2,
 *              "startAt": 1509539580,
 *              "createdAt": 1509529715,
 *              "updatedAt": 1509529715
 *          }
 *      ],
 *      "subscribed": false,
 *      "webPage": "localhost/courses/59f99873aec92b12848d39ce",
 *      "earnings": 0,
 *      "nearestSessionAt": 1509539580,
 *      "createdAt": 1509529715,
 *      "updatedAt": 1512466246,
 *      "subscribersCount": 666,
 *           "currency": "USD"
 * }
 * */

/**
 * @apiDefine CourseInfo
 * @apiSuccessExample {json} Course info for not owners:
 * {
 *   "code": 200,
 *   "result": {
 *       "id": "59f99873aec92b12848d39ce",
 *      "title": "asd",
 *      "description": "asd",
 *      "status": 1,
 *      "courseImageUrl": "",
 *      "courseIntroVideoUrl": "/uploads/5a2667467bdece1a84ae7567/SWxBVgg3aGOTeefvrQKYoBrFovzgc83b.mp4",
 *      "courseIntroVideoPreviewUrl": "/uploads/5a2667467bdece1a84ae7567/SWxBVgg3aGOTeefvrQKYoBrFovzgc83b.png",
 *      "courseImageSharingUrl": "/uploads/5a2667467bdece1a84ae7567/SWxBVgg3aGOTeefvrQKYoBrFovzgc83b.png",
 *      "intro": [
 *          {
 *              "id": "5a2666ea7bdece1a84ae7565",
 *              "type": 3,
 *              "fileUrl": "/uploads/5a2666ea7bdece1a84ae7565/OP5JhJ21sQw7okF67vZsWt6AHbInKFN3.jpg",
 *              "order": 1,
 *              "createdAt": 1512466154,
 *              "updatedAt": 1512466178
 *          },
 *          {
 *              "id": "5a2667467bdece1a84ae7567",
 *              "type": 1,
 *              "fileUrl": "/uploads/5a2667467bdece1a84ae7567/SWxBVgg3aGOTeefvrQKYoBrFovzgc83b.mp4",
 *              "fileThumbnailUrl": "/uploads/5a2667467bdece1a84ae7567/SWxBVgg3aGOTeefvrQKYoBrFovzgc83b.png",
 *              "order": 2,
 *              "createdAt": 1512466246,
 *              "updatedAt": 1512466299
 *          }
 *      ],
 *      "price": 0,
 *      "tier": "",
 *      "creatorId": "59e4799c9079d2638e46f305",
 *      "creatorName": "Andrey",
 *      "sessions": [
 *          {
 *              "id": "59f99873aec92b12848d39cf",
 *              "title": "asd",
 *              "description": "asd",
 *              "duration": 30,
 *              "courseId": "59f99873aec92b12848d39ce",
 *              "timeStatus": 2,
 *              "startAt": 1509539580,
 *              "createdAt": 1509529715,
 *              "updatedAt": 1509529715
 *          }
 *      ],
 *      "webPage": "localhost/courses/59f99873aec92b12848d39ce",
 *      "nearestSessionAt": 1509539580,
 *      "createdAt": 1509529715,
 *      "updatedAt": 1512466246,
 *      "subscribersCount": 666,
 *           "currency": "USD"
 *   }
 *}
 * */

/**
 * @apiDefine CourseShortList
 * @apiSuccessExample {json} Course list (short):
 * {
 *   "code": 200,
 *   "result": [
 *      {
 *          "id": "599da56dab0b51373049bfc6",
 *          "nearestSessionAt": 1507267186
 *          "createdAt": 1503503725,
 *          "updatedAt": 1503503725,
 *          "sortBy": 1503503725,
 *          "subscribersCount": 666,
 *           "currency": "USD"
 *      },
 *      {
 *          "id": "599da4afbba8422d344b4fde",
 *          "nearestSessionAt": 1523267186,
 *          "createdAt": 1503503535,
 *          "updatedAt": 1503503535,
 *          "sortBy": 1503503535,
 *          "subscribersCount": 666,
 *           "currency": "USD"
 *      },
 *      {
 *          "id": "599d9e3049763129b885d243",
 *          "nearestSessionAt": 1507457186,
 *          "createdAt": 1503501872,
 *          "updatedAt": 1503501872,
 *          "sortBy": 1503501872,
 *          "subscribersCount": 666,
 *           "currency": "USD"
 *      },
 *      {
 *          "id": "599d9deb49763129b885d242",
 *          "nearestSessionAt": 1507267154,
 *          "createdAt": 1503501803,
 *          "updatedAt": 1503501803,
 *          "sortBy": 1503501803,
 *          "subscribersCount": 666,
 *           "currency": "USD"
 *      }
 *
 *   ]
 *}
 * */

/**
 * @apiDefine CourseList
 * @apiSuccessExample {json} Course list:
 * {
 *   "code": 200,
 *   "result": [
 *       {
 *           "id": "59f99873aec92b12848d39ce",
 *           "title": "asd",
 *           "description": "asd",
 *           "courseImageUrl": "",
 *           "courseImageSharingUrl": "/uploads/5a2667467bdece1a84ae7567/SWxBVgg3aGOTeefvrQKYoBrFovzgc83b.png",
 *           "courseIntroVideoPreviewUrl": "/uploads/5a2667467bdece1a84ae7567/SWxBVgg3aGOTeefvrQKYoBrFovzgc83b.png",
 *           "creatorName": "Andrey",
 *           "webPage": "localhost/courses/59f99873aec92b12848d39ce",
 *           "subscribed": false,
 *           "nearestSessionAt": 1509539580,
 *           "createdAt": 1509529715,
 *           "updatedAt": 1512466246,
 *           "subscribersCount": 666,
 *           "currency": "USD"
 *       },
 *      {
 *          "id": "599da56dab0b51373049bfc6",
 *          "title": "Test",
 *          "description": "Test",
 *          "courseImageSharingUrl": "/uploads/5a2667467bdece1a84ae7567/SWxBVgg3aGOTeefvrQKYoBrFovzgc83b.png",
 *          "courseImageUrl": "/uploads/image-7g1rrt8qcyb7jykm0yjhouhaor-1503503725322.png",
 *          "courseIntroVideoPreviewUrl": "",
 *          "creatorName": "TestUser",
 *          "nearestSessionAt": 1523267186,
 *          "createdAt": 1503501803,
 *          "updatedAt": 1503501803,
 *          "subscribersCount": 666,
 *           "currency": "USD"
 *      }
 *  ]
 *}
 */

/**
 * @apiDefine SessionsList
 * @apiSuccessExample {json} Sessions List:
 * {
 *   "code": 200,
 *   "result": [
 *       {
 *           "id": "59a67e344e08131c400c87e4",
 *           "title": "test",
 *           "description": "test",
 *           "duration": 45,
 *           "courseId": "59a67e344e08131c400c87e3",
 *           "timeStatus": 1,
 *           "startAt": 1505725531,
 *           "createdAt": 1504083508,
 *           "updatedAt": 1504083508
 *       }
 *   ]
 * }
 * */

/**
 * @api {post} /api/v1/courses
 * @apiVersion 1.0.0
 * @apiName CreateCourse
 * @apiDescription Create course
 * @apiGroup Courses
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} title Course title
 * @apiParam {String} description Course description
 * @apiParam {String} [currency='USD'] currency
 * @apiParam {String} [price] Course price
 * @apiParam {String} [tier] Course tier
 * @apiParam {File} [image] Course image
 * @apiParam {Number} [status=0] Course status. For publish status is 1
 * @apiParam {Array} sessions Sessions data array
 *
 * @apiUse CourseResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * @apiErrorExample ValidationError
 * {
 *   "code": 400,
 *   "error": {
 *       "title": "Title is required",
 *       "description": "Description is required",
 *       "sessions": [
 *           {},
 *           {
 *               "startAt": "Session time is in past or cross with your other sessions"
 *           },
 *           {
 *               "title": "Title is required",
 *               "description": "Description is required",
 *               "startAt": "Session's start time is required",
 *               "duration": "Session's duration is required"
 *           }
 *       ]
 *   }
 * }
 * @apiParamExample {json} Request-Example:
 *     {
 *       "title": "Title",
 *       "description": "Description",
 *       "image": "Some course image file",
 *       "price": 10.5,
 *       "currency": "USD",
 *      "tier": "",
 *       "status": 1,
 *       "sessions":
 *                  [
 *                      {
 *                          "title": "Session title",
 *                          "description": "Session description",
 *                          "duration": 30,
 *                          "startAt": 1537437600
 *
 *                      },
 *                      {
 *                          "title": "Session title 2",
 *                          "description": "Session description 2",
 *                          "duration": 30,
 *                          "startAt": 1538437600
 *
 *                      }
 *                  ]
 *     }
 * */
router.post('', auth, imageUpload('image'), wrap(function* (req, res) {
    logger.log(`Try create course with parameters ${JSON.stringify(req.body)}`);
    if (!req.body.currency)
        req.body.currency = DEFAULT_CURRENCY;
    const validationError = yield validateCreateCourseParameters(req.user, req.body);
    if (validationError)
        return res.send(validationError);
    const course = yield createCourse(req.user, req.body, parseImageUrlFromFile(req.file));

    const {sessions = []} = req.body;
    yield sessions.map(sessionData => {
        const {title, description, duration, startAt} = sessionData;
        return createSession(course, title, description, duration, startAt);
    });
    yield course.populate('sessions').execPopulate();
    const courseDTO = course.toDTO();

    return res.send(apiResponse(courseDTO));
}));

/**
 * @api {get} /api/v1/courses/list
 * @apiVersion 1.0.0
 * @apiName ListCourse
 * @apiDescription List course
 * @apiGroup Courses
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {Number} [count=1000] Course count
 * @apiParam {Number} [page=1] Course list's page
 * @apiParam {Number} [sortMod=0] Mod for sorting courses (0 - CREATE, 1 - UPDATE, 2 - NEAREST_SESSION)
 * @apiParam {String} [userId] User id (for request only this user's courses) ! disables params: 'withoutMyCourses' and 'subscribed'
 * @apiParam {Number} [withoutMyCourses=0] Exclude (1) or Include(0) user courses (works if accessToken provided)
 * @apiParam {Boolean} [subscribed=0] If true returns only subscribed courses
 *
 * @apiUse CourseShortList
 * @apiUse UserDisabledError
 * @apiUse AccessDeniedError
 * */
router.get('/list', auth, wrap(function* (req, res) {
    try {
        const list = yield getList(req.user, req.query);
        return res.send(apiResponse(list));
    }
    catch (err) {
        return res.send(apiResponse(err));
    }
}));

/**
 * @api {post} /api/v1/courses/list
 * @apiVersion 1.0.0
 * @apiName CoursesByIds
 * @apiDescription Find courses by id
 * @apiGroup Courses
 *
 * @apiParam {Array} ids Courses' id
 *
 * @apiUse CourseList
 * @apiUse UserDisabledError
 * */
router.post('/list', softAuth, wrap(function* (req, res) {
    const list = yield findCoursesById(req.user, req.body);
    return res.send(apiResponse(list));
}));

/**
 * @api {get} /api/v1/courses/sessions/:courseId
 * @apiVersion 1.0.0
 * @apiName CourseSessions
 * @apiDescription Get course sessions
 * @apiGroup Courses
 *
 * @apiParam {String} accessToken
 * @apiParam {String} courseId Course id is provided in URL
 *
 * @apiUse SessionsList
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * @apiUse NotFoundError
 * @apiUse ValidationError
 * */
router.get('/sessions/:courseId', auth, wrap(function* (req, res) {
    try {
        const sessions = yield findCourseSessions(req.params.courseId);
        return res.send(apiResponse(sessions.map(session => {
            return session.toDTO()
        })));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {get} /api/v1/courses/:courseId
 * @apiVersion 1.0.0
 * @apiName CourseInfo
 * @apiDescription Get course info
 * @apiGroup Courses
 *
 * @apiParam {String} [accessToken] If access token provided and it is course owner, API return full course info
 * @apiParam {String} courseId Course id is provided in URL
 *
 * @apiUse CourseResponse
 * @apiUse CourseInfo
 * @apiUse UserDisabledError
 * @apiUse NotFoundError
 * @apiUse ValidationError
 * */
router.get('/:courseId', softAuth, wrap(function* (req, res) {
    try {
        const course = yield findCourse(req.user, req.params);
        return res.send(apiResponse(course));
    } catch (err) {
        return res.send(err);
    }
}));


/**
 * @api {put} /api/v1/courses/:courseId
 * @apiVersion 1.0.0
 * @apiName EditCourse
 * @apiDescription Edit course
 * @apiGroup Courses
 *
 * @apiParam {String} accessToken
 * @apiParam {String} courseId Course id is provided in URL
 * @apiParam {String} [title] New course title
 * @apiParam {String} [description] New course description
 * @apiParam {String} [price] New course price
 * @apiParam {String} [tier] New course tier
 * @apiParam {File} [image] New course image
 * @apiParam {Boolean} [isCourseImageShouldDelete=false] If need to delete course image
 * @apiParam {Boolean} [isCourseIntroVideoShouldDelete=false] if need to delete course intro video
 *
 * @apiUse CourseResponse
 * @apiUse CourseInfo
 * @apiUse UserDisabledError
 * @apiUse NotFoundError
 * @apiUse ValidationError
 * */
router.put('/:courseId', auth, imageUpload('image'), wrap(function* (req, res) {
    try {
        const imageUrl = req.file ? parseImageUrlFromFile(req.file) : null;
        const course = yield editCourse(req.user, req.params.courseId, req.body, imageUrl);
        return res.send(apiResponse(course.toDTO()));
    } catch (err) {
        return res.send(err);
    }
}));

/**
 * @api {delete} /api/v1/courses/:courseId
 * @apiVersion 1.0.0
 * @apiName DeleteCourse
 * @apiDescription Delete сourse
 * @apiGroup Courses
 *
 * @apiParam {String} accessToken
 * @apiParam {String} courseId Course id is provided in URL
 * @apiParam {Boolean} ignoreSubscribers The number of subscribers will be ignored ( 1 - true, 0 - false )
 *
 * @apiUse EmptySuccessResponse
 * @apiUse AccessDeniedError
 * @apiUse ValidationError
 * @apiUse NotFoundError
 * @apiUse deleteCourseWithActiveSessionError
 * @apiUse deleteCourseWithSubscribersError
 * */
router.delete('/:courseId', auth, wrap(function* (req, res) {
    const {courseId} = req.params;
    try {
        yield deleteCourse(req.user, courseId, Boolean(Number(req.body.ignoreSubscribers)));
        return res.send(apiResponse({}));
    } catch (err) {
        return res.send(err);
    }
}));

module.exports = router;
