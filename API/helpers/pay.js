'use strict';

const UserRepository = require('../repositories/UserRepository');
const notFoundError = require('../helpers/apiError').notFoundError;
const serverServiceError = require('../helpers/apiError').serverServiceError;
const stripePaymentError = require('../helpers/apiError').stripePaymentError;
const payFromBalanceError = require('../helpers/apiError').payFromBalanceError;

const config = require('../config');
const stripe = require('stripe')(config.stripeSecretKey);
const logger = require('../utils/logger');

const EDIT_USER_BALANCE_TYPES = require('../constants/editUserBalanceTypes');

const moneyUtils = require('../utils/money');
const currencyExponenta = require('../constants/currencyExponenta');


const payFromBalance = function* (user, amount, transaction) {
    if (!user)
        throw notFoundError(404, 'User is not found');
    if (user.credits < Number(amount))
        throw payFromBalanceError(user.credits, Number(amount));
    console.log('pay');
    return yield UserRepository.editUserBalance(user, Number(amount), EDIT_USER_BALANCE_TYPES.SUB, transaction);
};

const payFromCard = function* (user, amount, stripeToken, description, metadata = {}, discount) {
    if (!user)
        throw notFoundError(404, 'User is not found');
    const multiplicator = Math.pow(10, (currencyExponenta[metadata.currency] || 2));

    if (discount === 100) {
        return;
    }

    try {
        const charge = yield function* () {
            return yield stripe.charges.create({
                amount: parseInt(moneyUtils.roundMoney(amount * multiplicator)),
                currency: metadata.currency,
                description: description,
                metadata: metadata,
                source: stripeToken,
            });
        };
        logger.log(charge);
        return true;
    }
    catch (err) {
        logger.log(err);
        throw stripePaymentError(err.message);
    }
};

const payFromMixed = function* (user, price, stripeToken, description, metadata = {}, amountFromCard, transaction) {
    if (!user)
        throw notFoundError(404, 'User is not found');

    const amountFromBalance = Number(price) - Number(amountFromCard);

    if (user.credits < Number(amountFromBalance))
        throw payFromBalanceError(user.credits, Number(amountFromBalance));
    metadata.fullPrice = Number(price);
    metadata.amountFromCard = Boolean(metadata.amountFromCard) ? moneyUtils.roundMoney(metadata.amountFromCard) : moneyUtils.roundMoney(amountFromCard);

    metadata.amountFromBalance = moneyUtils.roundMoney(amountFromBalance);
    // step 1. Pay from the balance
    yield payFromBalance(user, Number(amountFromBalance), transaction);
    // step 2. Pay from the card
    return yield payFromCard(user, Number(amountFromCard), stripeToken, description, metadata);
};

module.exports = {
    payFromBalance,
    payFromCard,
    payFromMixed
};
