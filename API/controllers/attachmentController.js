'use strict';

const Router = require('router');
const wrap = require('co').wrap;

const createAttachment = require('../domain/attachmentsUtils').createAttachment;
const getAttachments = require('../domain/attachmentsUtils').getAttachments;

const auth = require('../helpers/auth');
const apiResponse = require('../helpers/apiResponse');

const router = Router();

/**
 * @apiDefine AttachmentResponse
 * @apiSuccessExample {json} Attachment:
 * {
 *   "code": 200,
 *   "result": {
 *              "id": "59d604b84e199b056c43425b",
 *              "type": 1,
 *              "createdAt": 1507198136,
 *              "updatedAt": 1507198459,
 *              "fileUrl": "/uploads/59d604b84e199b056c43425b/M6ZFNvgjVI2VTbA3NnjJpSXZQeuInsnb.mp4",
 *              "fileThumbnailUrl": "/uploads/59d604b84e199b056c43425b/M6ZFNvgjVI2VTbA3NnjJpSXZQeuInsnb.png"
 *            }
 * }
 * */
/**
 * @apiDefine AttachmentsListResponse
 * @apiSuccessExample {json} Attachments List:
 * {
 *   "code": 200,
 *   "result": [
 *       {
 *          "id": "59d604b84e199b056c43425b",
 *          "type": 1,
 *          "createdAt": 1507198136,
 *          "updatedAt": 1507198459,
 *          "fileUrl": "/uploads/59d604b84e199b056c43425b/M6ZFNvgjVI2VTbA3NnjJpSXZQeuInsnb.mp4",
 *          "fileThumbnailUrl": "/uploads/59d604b84e199b056c43425b/M6ZFNvgjVI2VTbA3NnjJpSXZQeuInsnb.png"
 *      }
 *   ]
 * }
 * */

/**
 * @api {get} /api/v1/attachments/all/:courseId
 * @apiVersion 1.0.0
 * @apiName GetAttachments
 * @apiDescription Get course attachments
 * @apiGroup Attachments
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} courseId Provided in URL
 *
 * @apiUse AttachmentsListResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * @apiUse NotFoundError
 * */
router.get('/all/:courseId', auth, wrap(function* (req, res) {
    try {
        const attachments = yield getAttachments(req.user, req.params.courseId);
        return res.send(apiResponse(attachments.map(attachment => {
            return attachment.toDTO();
        })));
    } catch (err) {
        res.send(err);
    }
}));

/**
 * @api {post} /api/v1/attachments/:courseId
 * @apiVersion 1.0.0
 * @apiName CreateAttachment
 * @apiDescription Create Attachment
 * @apiGroup Attachments
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} courseId Provided in URL
 * @apiParam {String} type Attachment type. 1 = Video; 2 = Image; 3 = PDF; 4 = Link
 *
 * @apiUse AttachmentResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * @apiUse NotFoundError
 * */
router.post('/:courseId', auth, wrap(function* (req, res) {
    try {
        const attachment = yield createAttachment(req.user, req.params.courseId, req.body);
        return res.send(attachment.toDTO());
    } catch (err) {
        res.send(err);
    }
}));

module.exports = router;
