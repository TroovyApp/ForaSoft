'use strict';

const PHONE_NUMBERS = ['+15005550006', '+15005550002'];
const TEST_CODE = 77777;

function isTestPhoneNumber(phoneNumberWithCode){
    return PHONE_NUMBERS.includes(phoneNumberWithCode);
}

module.exports = {
    PHONE_NUMBERS,
    isTestPhoneNumber,
    TEST_CODE
};
