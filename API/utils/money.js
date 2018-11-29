'use strict';

const roundMoney = (amount, digits = 2) => {
    return (Number(amount)).toFixed(digits);
};

const roundPercent = (precent) => {
    return (Number(precent)).toFixed(2);
};

const getAmountTax = (amount, tax) => {
    return Number(roundMoney(Number(amount) * roundPercent(tax)));
};

const getAmountAfterTax = (amount, tax) => {
    const amountTax = getAmountTax(amount, tax);
    return Number(amountTax) >= Number(amount) ? 0 : roundMoney(Number(amount) - Number(amountTax));
};

module.exports = {
    roundMoney,
    getAmountAfterTax
};
