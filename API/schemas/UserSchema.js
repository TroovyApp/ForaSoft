const mongoose = require('mongoose');
const moment = require('moment');
const Schema = mongoose.Schema;

const roundMoney = require('../utils/money').roundMoney;

const UserSchema = new Schema({
    dialCode: String,
    phoneNumber: String,
    accessToken: {type: Array, default: []},
    name: String,
    imageUrl: String,
    isDisabled: {type: Boolean, default: false},
    credits: {type: Number, default: 0},
    reservedCredits: {type: Number, default: 0},
    reports: {type: Number, default: 0},
    createdAt: {type: Date},
    updatedAt: {type: Date},
    courses: [{type: Schema.ObjectId, ref: 'Course'}],
    userDevicesData: {type: Schema.Types.Mixed, default: {}},
    email: {type: String},
    lastPaymentDetails: {type: Schema.Types.Mixed},
    timezoneOffset: {type: Number, default: 0},
    currency: {type: String}
}, {collection: 'User', usePushEach: true});

UserSchema.pre('save', function (next) {
    this.credits = roundMoney(this.credits);
    this.reservedCredits = roundMoney(this.reservedCredits);
    if (!this.createdAt)
        this.createdAt = moment().utc().valueOf();
    this.updatedAt = moment().utc().valueOf();
    next();
});

UserSchema.pre('update', function (next) {
    this.credits = roundMoney(this.credits);
    this.reservedCredits = roundMoney(this.reservedCredits);
    this.update({}, {$set: {updatedAt: moment().utc().valueOf()}});
    next();
});

UserSchema.methods.reserveCredits = function (amount) {
    const amountCredits = Number(amount);
    if (amountCredits < 0)
        return null;
    if (this.credits < amountCredits)
        return null;

    this.credits = this.credits - amountCredits;
    this.reservedCredits = this.reservedCredits + amountCredits;
    return this;
};

UserSchema.methods.withdrawalReservedCredits = function (amount) {
    const amountCredits = Number(amount);
    if (amountCredits < 0)
        return null;
    if (this.reservedCredits < amountCredits)
        return null;

    this.reservedCredits = this.reservedCredits - amountCredits;
    return this;
};

UserSchema.methods.toDTO = function () {
    return {
        id: this._id,
        dialCode: this.dialCode,
        phoneNumber: this.phoneNumber,
        accessToken: this.accessToken[this.accessToken.length - 1],
        imageUrl: Boolean(this.imageUrl) ? this.imageUrl : '',
        name: this.name,
        credits: this.credits,
        email: this.email ? this.email : '',
        createdAt: moment(this.createdAt).unix(),
        updatedAt: moment(this.updatedAt).unix(),
        currency: this.currency
    }
};

UserSchema.methods.toShortDTO = function () {
    return {
        id: this._id,
        imageUrl: Boolean(this.imageUrl) ? this.imageUrl : '',
        name: this.name,
        email: this.email ? this.email : '',
        currency: this.currency
    }
};

UserSchema.methods.toInfo = function () {
    return {
        imageUrl: Boolean(this.imageUrl) ? this.imageUrl : '',
        name: this.name,
        dialCode: this.dialCode,
        phoneNumber: this.phoneNumber,
        credits: this.credits,
        reservedCredits: this.reservedCredits,
        email: this.email ? this.email : '',
        currency: this.currency
    }
};

UserSchema.methods.toAdminView = function () {
    return {
        id: this._id,
        dialCode: this.dialCode,
        phoneNumber: this.phoneNumber,
        imageUrl: Boolean(this.imageUrl) ? this.imageUrl : '',
        name: this.name,
        credits: this.credits,
        createdAt: moment(this.createdAt).unix(),
        updatedAt: moment(this.updatedAt).unix(),
        isDisabled: this.isDisabled,
        email: this.email ? this.email : '',
        currency: this.currency
    }
};

module.exports = mongoose.model('User', UserSchema);
