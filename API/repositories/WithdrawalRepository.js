'use strict';

const WithdrawalModel = require('../schemas/WithdrawalSchema');

class WithdrawalRepository {

    static* createWithdrawal(user, amountCredits, bankAccountNumber) {
        return yield WithdrawalModel.create({
            user: user._id,
            amountCredits,
            bankAccountNumber,
            currency: user.currency
        });
    }

    static* getWithdrawalById(id) {
        return yield WithdrawalModel.findOne({_id: {$eq: id}})
            .exec();
    }

    static* getWithdrawalCount() {
        return yield WithdrawalModel.count({});
    }

    static* getWithdrawalList(count, page) {
        const skip = Number(count) * (Number(page) - 1) >= 0 ? Number(count) * (Number(page) - 1) : 0;
        return yield WithdrawalModel.find({})
            .sort({createdAt: -1})
            .limit(Number(count))
            .skip(skip)
            .populate('user')
            .exec();
    }

    static* approveWithdrawal(withdrawal, isUnapproved = false) {
        const newState = !isUnapproved;
        yield WithdrawalModel.update({_id: withdrawal._id}, {$set: {isApproved: newState}});
        return yield WithdrawalModel.findOne({_id: withdrawal.id}).populate('user').exec();
    }
}

module.exports = WithdrawalRepository;
