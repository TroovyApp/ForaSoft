'use strict';

const ConfirmationModel = require('../schemas/ConfirmationSchema');

const MIN_CODE = 10000;
const MAX_CODE = 99999;

const {TEST_CODE, isTestPhoneNumber} = require('../constants/testAccounts');

class ConfirmationRepository {
    static* createConfirmation(appGeneratedToken, dialCode, phoneNumber) {
        yield ConfirmationRepository.deleteConfirmation(appGeneratedToken);
        const phoneNumberWithCode = dialCode + phoneNumber;
        const confirmationCode = isTestPhoneNumber(phoneNumberWithCode) ? TEST_CODE : generateConfirmationCode();
        return yield ConfirmationModel.create({appGeneratedToken, dialCode, phoneNumber, confirmationCode});
    }

    static* verifyConfirmationCode(appGeneratedToken, confirmationCode) {
        const confirmation = yield ConfirmationModel.findOne({
            appGeneratedToken,
            confirmationCode,
            isVerified: false
        }).exec();

        if (!confirmation)
            return null;

        confirmation.isVerified = true;
        yield confirmation.save();
        return confirmation;
    }

    static* deleteConfirmation(appGeneratedToken) {
        yield ConfirmationModel.remove({appGeneratedToken});
    }

    static* isPhoneNumberConfirmed(appGeneratedToken) {
        const confirmation = yield ConfirmationModel.findOne({appGeneratedToken, isVerified: true}).exec();
        return Boolean(confirmation);
    }
}

const generateConfirmationCode = () => {
    return Math.floor(Math.random() * (MAX_CODE - MIN_CODE + 1)) + MIN_CODE;
};

module.exports = ConfirmationRepository;
