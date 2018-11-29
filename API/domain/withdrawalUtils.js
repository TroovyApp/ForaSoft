'use strict';

const WithdrawalRepository = require('../repositories/WithdrawalRepository');

const notFoundError = require('../helpers/apiError').notFoundError;
const validationError = require('../helpers/apiError').validationError;
const validateObjectId = require('../helpers/validators/validateObjectId');
const serverServiceError = require('../helpers/apiError').serverServiceError;

const withdrawalErrors = require('../helpers/errors/withdrawalErrors');

const creditsOperations = require('../helpers/creditsOperations');

const DEFAULT_WITHDRAWALS_COUNT = 20;
const DEFAULT_WITHDRAWALS_PAGE = 1;


const createWithdrawal = function*(user, body) {
    const {bankAccountNumber = ''} = body;
    const amountCredits = Number(body.amountCredits);
    if (Number(user.credits) < Number(amountCredits))
        throw withdrawalErrors.createWithdrawalWithLessBalance(Number(amountCredits), Number(user.credits));

    const updatedUser = yield creditsOperations.reserveCredits(user.id, amountCredits);
    if (!Boolean(updatedUser))
        throw serverServiceError('Reservation failed');

    return yield WithdrawalRepository.createWithdrawal(user, amountCredits, bankAccountNumber);
};

const getWithdrawalList = function*(query) {
    const {
        count = DEFAULT_WITHDRAWALS_COUNT,
        page = DEFAULT_WITHDRAWALS_PAGE,
    } = query;
    let list = yield WithdrawalRepository.getWithdrawalList(count, page);
    list = list.map(withdrawal => withdrawal.toAdminDTO());
    const totalAll = yield WithdrawalRepository.getWithdrawalCount();
    const result = {
        items: list,
        total: list.length,
        totalAll
    };

    return result;
};

const approveWithdrawal = function*(req) {
    const {withdrawalId} = req.params;
    if (!validateObjectId(withdrawalId)) {
        throw validationError('WithdrawalId is not valid');
    }
    const withdrawal = yield WithdrawalRepository.getWithdrawalById(withdrawalId);

    if (!withdrawal) {
        throw notFoundError('Withdrawal is not found');
    }
    if (Boolean(withdrawal.isApproved)) {
        throw validationError('Withdrawal is approved earlier');
    }
    const updatedUser = yield creditsOperations.withdrawalReservedCredits(withdrawal.user.toString(), withdrawal.amountCredits);
    if (!Boolean(updatedUser))
        throw serverServiceError('Withdrawal reserved credits failed');

    return yield WithdrawalRepository.approveWithdrawal(withdrawal);
};


module.exports = {
    createWithdrawal,
    getWithdrawalList,
    approveWithdrawal
};
