const mongoose = require('mongoose');
const moment = require('moment');
const Schema = mongoose.Schema;

const REPORT_ENTITY_TYPES = require('../constants/reportEntityTypes');


const ReportSchema = new Schema({
    targetId: String,
    targetType: {Number, default: REPORT_ENTITY_TYPES.NONE},
    reason: String,
    creator: {type: Schema.ObjectId, ref: 'User'},
    createdAt: {type: Date},
    updatedAt: {type: Date}
}, {collection: 'Report'});

ReportSchema.pre('save', function (next) {
    if (!this.createdAt)
        this.createdAt = moment().utc().valueOf();
    this.updatedAt = moment().utc().valueOf();
    next();
});

ReportSchema.pre('update', function (next) {
    this.update({}, {$set: {updatedAt: moment().utc().valueOf()}});
    next();
});

module.exports = mongoose.model('Report', ReportSchema);
