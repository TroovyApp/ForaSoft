'use strict';

const ReportModel = require('../schemas/ReportSchema');


class ReportRepository {
    static* createReport(user, reason, targetId, targetType) {
        return yield ReportModel.create({
            targetId,
            targetType,
            reason,
            creator: user._id,
        });
    }
}

module.exports = ReportRepository;
