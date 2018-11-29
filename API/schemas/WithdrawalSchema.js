const mongoose = require('mongoose');
const moment = require('moment');
const Schema = mongoose.Schema;

const roundMoney = require('../utils/money').roundMoney;


const WithdrawalSchema = new Schema({
    user: {type: Schema.ObjectId, ref: 'User'},
    bankAccountNumber: String,
    amountCredits: Number,
    currency: {type: String},
    createdAt: {type: Date},
    updatedAt: {type: Date},
    isApproved: {type: Boolean, default: false}
}, {collection: 'Withdrawal'});

WithdrawalSchema.pre('save', function (next) {
    this.amountCredits = roundMoney(this.amountCredits);
    if (!this.createdAt)
        this.createdAt = moment().utc().valueOf();
    this.updatedAt = moment().utc().valueOf();
    next();
});

WithdrawalSchema.pre('update', function (next) {
    this.amountCredits = roundMoney(this.amountCredits);
    this.update({}, {$set: {updatedAt: moment().utc().valueOf()}});
    next();
});

WithdrawalSchema.methods.toDTO = function () {
    return {
        id: this._id,
        user: this.user.toInfo(),
        amountCredits: this.amountCredits,
        createdAt: moment(this.createdAt).unix(),
        currency: this.currency
    }
};

WithdrawalSchema.methods.toAdminDTO = function () {
    return {
        id: this._id,
        user: this.user.toInfo(),
        bankAccountNumber: this.bankAccountNumber,
        amountCredits: this.amountCredits,
        createdAt: moment(this.createdAt).unix(),
        updatedAt: moment(this.updatedAt).unix(),
        isApproved: this.isApproved,
        currency: this.currency
    }
};


module.exports = mongoose.model('Withdrawal', WithdrawalSchema);
