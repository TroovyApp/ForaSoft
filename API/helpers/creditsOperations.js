'use strict';

const UserRepository = require('../repositories/UserRepository');

const notFoundError = require('../helpers/apiError').notFoundError;
const validationError = require('../helpers/apiError').validationError;
const serverServiceError = require('../helpers/apiError').serverServiceError;

const validateObjectId = require('../helpers/validators/validateObjectId');


const reserveCredits = function*(userId, amount = 0) {
    const amountCredits = Number(amount);
    if (amountCredits < 0)
        throw serverServiceError('Amount should be more than 0');

    if (!validateObjectId(userId))
        throw validationError('userId id is not valid');

    const user = yield UserRepository.getUserById(userId);

    if (!user)
        throw notFoundError(404, 'User is not found');

    if (user.credits < amountCredits)
        throw validationError(`User's balance should be more than ${amountCredits}`);

    const updatedUser = user.reserveCredits(amountCredits);
    if (!Boolean(updatedUser))
        throw validationError('Reservation failed');

    return yield updatedUser.save();
};

const withdrawalReservedCredits = function*(userId, amount = 0) {
    const amountCredits = Number(amount);
    if (amountCredits < 0)
        throw serverServiceError('Amount should be more than 0');

    if (!validateObjectId(userId))
        throw validationError('userId id is not valid');

    const user = yield UserRepository.getUserById(userId);

    if (!user)
        throw notFoundError(404, 'User is not found');

    if (user.reservedCredits < amountCredits)
        throw validationError(`User's reserved credits should be more than ${amountCredits}`);

    const updatedUser = user.withdrawalReservedCredits(amountCredits);
    if (!Boolean(updatedUser))
        throw validationError('Withdrawal reserved credits failed');

    return yield updatedUser.save();
};

module.exports = {
    reserveCredits,
    withdrawalReservedCredits
};
