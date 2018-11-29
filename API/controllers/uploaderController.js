'use strict';

const Router = require('router');
const wrap = require('co').wrap;

const auth = require('../helpers/auth');
const uploadChunk = require('../helpers/chunkUploader');
const saveChunk = require('../domain/uploadUtils').saveChunk;
const finishUpload = require('../domain/uploadUtils').finishUpload;

const apiResponse = require('../helpers/apiResponse');
const validateUploadParameters = require('../helpers/validators/uploadValidator');
const logger = require('../utils/logger');

const router = Router();

/**
 * @apiDefine ChunkResponse
 * @apiSuccessExample {json} Chunk response:
 * {
 *   "code": 200,
 *   "result": {
 *       "dataId": "59a67e344e08131c400c87e3",
 *       "entityId": "599da56dab0b51373049bfc6",
 *       "entityType": "1"
 *   }
 * }
 * */
/**
 * @api {post} /api/v1/upload
 * @apiVersion 1.0.0
 * @apiName Upload
 * @apiDescription Upload chunk
 * @apiGroup Upload
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} [dataId] If there is not first request, you need to provide data id from previous request
 * @apiParam {String} entityId Id of entity of file
 * @apiParam {Number} entityType Intro video = 1; Video Attachment = 2
 * @apiParam {Boolean} [isLast] If there is last request, it is true, otherwise false
 * @apiParam {File} chunk Chunk
 *
 * @apiUse ChunkResponse
 * @apiUse CourseResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * @apiUse ValidationError
 * @apiUse NotFoundError
 */
router.post('', auth, uploadChunk('chunk'), wrap(function* (req, res) {
    const validationError = validateUploadParameters(req.body);
    if (validationError)
        return res.send(validationError);

    logger.log(`Start uploading chunk for entity ${req.body.entityId} with type ${req.body.entityType} isLast ${req.body.isLast}. User ${req.user._id}`);
    try {
        const response = yield saveChunk(req.user, req.file ? req.file.path : "", req.body);
        res.send(apiResponse(response));
    } catch (err) {
        res.send(err);
    }
}));


/**
 * @api {post} /api/v1/upload/finish
 * @apiVersion 1.0.0
 * @apiName FinishUpload
 * @apiDescription Finish chunk uploading
 * @apiGroup Upload
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} dataId Upload id
 * @apiParam {String} entityId Id of entity of file
 * @apiParam {Number} entityType Intro video = 1; Video Attachment = 2
 *
 * @apiUse EmptySuccessResponse
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * @apiUse ValidationError
 * @apiUse NotFoundError
 */
router.post('/finish', auth, wrap(function* (req, res) {
    const validationError = validateUploadParameters(req.body);
    if (validationError)
        return res.send(validationError);

    logger.log(`Finish uploading ${req.body.dataId}`);
    try {
        yield finishUpload(req.user, req.body);
        res.send(apiResponse({}));
    } catch (err) {
        res.send(err);
    }
}));

module.exports = router;
