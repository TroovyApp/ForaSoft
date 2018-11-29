'use strict';

const twilioClient = require('./twilio');
const config = require('../config');
const ConfirmationRepository = require('../repositories/ConfirmationRepository');
const serviceError = require('../helpers/apiError').serverServiceError;
const {isTestPhoneNumber} = require('../constants/testAccounts');

class VerificationService {
    * sendVerificationCode(appGeneratedToken, dialCode, phoneNumber) {
        const confirmation = yield ConfirmationRepository.createConfirmation(appGeneratedToken, dialCode, phoneNumber);
        const phoneNumberWithCode = dialCode + phoneNumber;

        if (isTestPhoneNumber(phoneNumberWithCode))
            return;

        try {
            const message = formatMessage(confirmation.confirmationCode, phoneNumberWithCode);
            yield twilioClient.messages.create(message);
        } catch (err) {
            yield ConfirmationRepository.deleteConfirmation(appGeneratedToken);
            const message = err.message.replace(new RegExp(/\s'To'/), '');
            throw serviceError(message);
        }
    }
}

const formatMessage = (code, phoneNumberWithCode) => {
    return {
        body: `Your confirmation code is ${code}`,
        to: phoneNumberWithCode,
        from: config.twilioPhoneNumber
    };
};

module.exports = new VerificationService();
