'use strict';

const Router = require('router');
const wrap = require('co').wrap;

const apiResponse = require('../helpers/apiResponse');
const auth = require('../helpers/auth');
const softAuth = require('../helpers/softAuth');

const validateCreateReportParameters = require('../helpers/validators/createReportValidator');

const createReport = require('../domain/reportesUtils').createReport;

const logger = require('../utils/logger');

const router = Router();


/**
 * @api {post} /api/v1/reports
 * @apiVersion 1.0.0
 * @apiName CreateReport
 * @apiDescription Create report
 * @apiGroup Report
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} targetId Target of report
 * @apiParam {Number} targetType Type of Target ([0 - none], 1 - course, 2 - session )
 * @apiParam {String} reason Text description for report
 */
router.post('', auth, wrap(function* (req, res) {
    logger.log(`Try create report with parameters ${JSON.stringify(req.body)}`);

    const validationError = yield validateCreateReportParameters(req.user, req.body);
    if (validationError)
        return res.send(validationError);
    
    const report = yield createReport(req.user, req.body);

    return res.send(apiResponse(report.toJSON));
}));


module.exports = router;
