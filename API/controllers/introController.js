'use strict';

const Router = require('router');
const wrap = require('co').wrap;

const {createIntro, deleteIntro, updateIntroOrder} = require('../domain/introUtils');

const auth = require('../helpers/auth');
const apiResponse = require('../helpers/apiResponse');

const router = Router();

/**
 * @apiDefine IntroResponse
 * @apiSuccessExample {json} Intro:
 * {
 *   "code": 200,
 *   "result": {
 *              "id": "59d604b84e199b056c43425b",
 *              "type": 1,
 *              "createdAt": 1507198136,
 *              "updatedAt": 1507198459,
 *              "fileUrl": "/uploads/59d604b84e199b056c43425b/M6ZFNvgjVI2VTbA3NnjJpSXZQeuInsnb.mp4",
 *              "fileThumbnailUrl": "/uploads/59d604b84e199b056c43425b/M6ZFNvgjVI2VTbA3NnjJpSXZQeuInsnb.png",
 *              "order": 1
 *            }
 * }
 * */

/**
 * @api {delete} /api/v1/intro/:introId
 * @apiVersion 1.0.0
 * @apiName DeleteIntro
 * @apiDescription Delete intro
 * @apiGroup Intro
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} introId Provided in URL
 *
 * @apiUse EmptySuccessResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * @apiUse NotFoundError
 * @apiUse ValidationError
 * */
router.delete('/:introId', auth, wrap(function* (req, res) {
    try {
        yield deleteIntro(req.user, req.params.introId);
        return res.send(apiResponse({}));
    } catch (err) {
        res.send(err);
    }
}));

/**
 * @api {post} /api/v1/intro/:courseId
 * @apiVersion 1.0.0
 * @apiName CreateIntro
 * @apiDescription Create Intro
 * @apiGroup Intro
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} courseId Provided in URL
 * @apiParam {String} type Upload type type. 1 = Video; 3 = Image;
 * @apiParam {Number} order Intro order (1,2,3)
 *
 * @apiUse IntroResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * @apiUse NotFoundError
 * @apiUse ValidationError
 * */
router.post('/:courseId', auth, wrap(function* (req, res) {
    try {
        const intro = yield createIntro(req.user, req.params.courseId, req.body);
        return res.send(intro.toDTO());
    } catch (err) {
        res.send(err);
    }
}));


/**
 * @apiDefine IntroListResponse
 * @apiSuccessExample {json} Intro:
 * {
 *   "code": 200,
 *   "result": [
 *              {
 *                  "id": "59d604b84e199b056c43425b",
 *                  "type": 1,
 *                  "createdAt": 1507198136,
 *                  "updatedAt": 1507198459,
 *                  "fileUrl": "/uploads/59d604b84e199b056c43425b/M6ZFNvgjVI2VTbA3NnjJpSXZQeuInsnb.mp4",
 *                  "fileThumbnailUrl": "/uploads/59d604b84e199b056c43425b/M6ZFNvgjVI2VTbA3NnjJpSXZQeuInsnb.png",
 *                  "order": 1
 *            },
 *            {
 *                  "id": "59d604b84e199b056c43425b",
 *                  "type": 1,
 *                  "createdAt": 1507198136,
 *                  "updatedAt": 1507198459,
 *                  "fileUrl": "/uploads/59d604b84e199b056c43425b/M6ZFNvgjVI2VTbA3NnjJpSXZQeuInsnb.mp4",
 *                  "fileThumbnailUrl": "/uploads/59d604b84e199b056c43425b/M6ZFNvgjVI2VTbA3NnjJpSXZQeuInsnb.png",
 *                  "order": 2
 *            }
 *   ]
 * }
 * */

/**
 * @api {delete} /api/v1/intro/:introId
 * @apiVersion 1.0.0
 * @apiName DeleteIntro
 * @apiDescription Delete intro
 * @apiGroup Intro
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} introId Provided in URL
 *
 * @apiUse EmptySuccessResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * @apiUse NotFoundError
 * @apiUse ValidationError
 * */
router.delete('/:introId', auth, wrap(function* (req, res) {
    try {
        yield deleteIntro(req.user, req.params.introId);
        return res.send(apiResponse({}));
    } catch (err) {
        res.send(err);
    }
}));


/**
 * @api {put} /api/v1/intro/
 * @apiVersion 1.0.0
 * @apiName UpdateIntroOrder
 * @apiDescription Update intro order
 * @apiGroup Intro
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {Array} orderData Array with order and id of
 *
 * @apiParamExample {json} Request-Example:
 *     {
 *       "orderData": [
 *              {
 *                  "id": "59d604b84e199b056c43425b",
 *                  "order": 2
 *            },
 *            {
 *                  "id": "59d604b84e1998056c434789",
 *                  "order": 1
 *            }
 *       ]
 *     }
 *
 * @apiUse IntroListResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * */
router.put('', auth, wrap(function* (req, res) {
    try {
        const list = yield updateIntroOrder(req.body);
        return res.send(apiResponse(list.map(intro => {
            return intro.toDTO();
        })));
    } catch (err) {
        res.send(err);
    }
}));

module.exports = router;