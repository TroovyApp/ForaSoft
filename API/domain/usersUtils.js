'use strict';

const verificationService = require('../utils/VerificationService');
const ConfirmationRepository = require('../repositories/ConfirmationRepository');
const UserRepository = require('../repositories/UserRepository');

const validateObjectId = require('../helpers/validators/validateObjectId');
const appConfig = require('../constants/appConstants');
const parseQualities = require('../helpers/qualitiesParser');
const FileUtils = require('../helpers/FileUtils');

const notFoundError = require('../helpers/apiError').notFoundError;
const accountIsNotVerifiedError = require('../helpers/apiError').accountIsNotVerifiedError;
const userDisabledError = require('../helpers/apiError').userDisabledError;
const validationError = require('../helpers/apiError').validationError;

const InternalRoute = require('../sockets/routes/InternalRoute');
const sessionsUtils = require('./sessionsUtils');

const DEFAULT_USERS_COUNT = 20;
const DEFAULT_USERS_PAGE = 1;

const USER_FIELDS = ['name', 'email'];

const parseUserQualities = function (body, imageUrl, removeAvatar = false) {
    const qualities = parseQualities(body, USER_FIELDS);
    if (imageUrl) {
        qualities.imageUrl = imageUrl;
    }
    if (removeAvatar) {
        qualities.imageUrl = '';
    }
    return qualities;
};

const verifyPhoneNumber = function* (body) {
    const {dialCode, phoneNumber, appGeneratedToken} = body;
    const isDisabled = yield UserRepository.isUserDisabled(dialCode, phoneNumber);
    if (isDisabled)
        throw userDisabledError();
    yield verificationService.sendVerificationCode(appGeneratedToken, dialCode, phoneNumber);
};

const confirmPhoneNumber = function* (body) {
    const {confirmationCode, appGeneratedToken} = body;
    const confirmation = yield ConfirmationRepository.verifyConfirmationCode(appGeneratedToken, confirmationCode);
    if (!confirmation) {
        throw notFoundError(404, "Confirmation code is not found");
    }
    const user = yield UserRepository.tryLoginUser(confirmation.dialCode, confirmation.phoneNumber);
    if (!user) {
        return {};
    }
    if (user.isDisabled) {
        throw userDisabledError();
    }
    /** User is logged in, so no need to store confirmation more */
    yield ConfirmationRepository.deleteConfirmation(appGeneratedToken);
    return user.toDTO();
};

const registerUser = function* (body, imageUrl) {
    const {appGeneratedToken, dialCode, phoneNumber, name} = body;
    const isPhoneNumberConfirmed = yield ConfirmationRepository.isPhoneNumberConfirmed(appGeneratedToken);
    if (!isPhoneNumberConfirmed)
        throw accountIsNotVerifiedError();
    /** User is logged in, so no need to store confirmation more */
    yield ConfirmationRepository.deleteConfirmation(appGeneratedToken);
    let user = yield UserRepository.tryLoginUser(dialCode, phoneNumber);
    if (user && user.isDisabled)
        throw userDisabledError();
    if (user)
        return user.toDTO();
    user = yield UserRepository.registerUser(dialCode, phoneNumber, name, imageUrl);
    return user.toDTO();
};

const editUser = function* (user, body, imageUrl, removeAvatar = false) {
    try {
        if (!user)
            throw notFoundError(404, 'User is not found');
        if ((imageUrl || removeAvatar) && user.imageUrl) {
            yield FileUtils.deleteFile(user.imageUrl);
        }
        const userQualities = parseUserQualities(body, imageUrl, removeAvatar);
        return yield UserRepository.updateUser(user, userQualities);
    }
    catch (err) {
        try {
            // Remove uploaded image if exists any error
            if (imageUrl)
                yield FileUtils.deleteFile(imageUrl);
        }
        catch (err_remove) {
            throw err;
        }
        throw err;
    }
};

const logoutUser = function* (user, accessToken) {
    return yield UserRepository.logout(user, accessToken);
};

const findUsersById = function* (body) {
    const {ids = []} = body;
    const searchIds = ids.filter(id => {
        return validateObjectId(id);
    });
    const users = yield UserRepository.getUsersById(searchIds);
    return users.map(user => {
        return user.toShortDTO();
    });
};

const reportUserById = function* (userId) {
    if (!validateObjectId(userId)) {
        throw validationError('UserId is not valid');
    }

    const user = yield UserRepository.getUserById(userId);
    if (!user) {
        throw notFoundError('User is not found');
    }

    return yield UserRepository.reportUser(user);
};


const disableUser = function* (req) {
    const {userId} = req.params;
    const isEnable = Boolean(Number(req.body.isEnable));
    if (!validateObjectId(userId)) {
        throw validationError('UserId is not valid');
    }
    const user = yield UserRepository.getUserById(userId);
    if (!user) {
        throw notFoundError('User is not found');
    }
    const updatedUser = yield UserRepository.disableUser(user, isEnable);
    if (!isEnable) {
        InternalRoute.emit('internal:emitToUser', user.id, 'session:forceLogout', userDisabledError());
        const sessionIds = yield UserRepository.getMySessionIds(updatedUser);

        try {
            yield sessionIds.map((sessionId) => {
                return sessionsUtils.finishSession(updatedUser, sessionId);
            });
        }
        catch (err) {
            // ignore errors
        }

    }

    return updatedUser;
};

const getUsersList = function* (query) {
    const {
        count = DEFAULT_USERS_COUNT,
        page = DEFAULT_USERS_PAGE,
    } = query;
    const list = yield UserRepository.getUsersList(count, page);
    const totalAll = yield UserRepository.getUsersCount();
    const result = {
        items: list.map(user => user.toAdminView()),
        total: list.length,
        totalAll
    };

    return result;
};

const saveUserDeviceData = function* (user, accessToken, body) {
    yield UserRepository.saveDeviceData(user, accessToken, body);
    return {
        subscribeServiceTax: appConfig.SUBSCRIBE_SERVICE_TAX,
        payoutServiceTax: appConfig.PAYOUT_SERVICE_TAX,
        minimumPayoutAmount: appConfig.MINIMUM_PAYOUT_AMOUNT
    }
};

const saveUserEmail = function* (user, email) {
    user.email = email;
    yield user.save();
    return user;
};

module.exports = {
    verifyPhoneNumber,
    confirmPhoneNumber,
    registerUser,
    editUser,
    logoutUser,
    findUsersById,
    disableUser,
    getUsersList,
    saveUserDeviceData,
    reportUserById,
    saveUserEmail
};
