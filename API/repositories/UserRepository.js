'use strict';

const randtoken = require('rand-token');

const UserModel = require('../schemas/UserSchema');
const editUserBalanceTypes = require('../constants/editUserBalanceTypes');


class UserRepository {
    static* tryLoginUser(dialCode, phoneNumber) {
        const user = yield UserModel.findOne({dialCode, phoneNumber}).exec();
        if (!user)
            return null;
        user.accessToken.push(randtoken.generate(32));
        yield user.save();
        return user;
    }

    static* registerUser(dialCode, phoneNumber, name, imageUrl) {
        yield UserModel.create({dialCode, phoneNumber, name, imageUrl});
        return yield UserRepository.tryLoginUser(dialCode, phoneNumber);
    }

    static* updateUser(user, qualities) {
        yield UserModel.update({_id: user._id}, {$set: qualities});
        return yield UserModel.findOne({_id: user.id}).exec();
    }

    static* findByAccessToken(accessToken) {
        return yield UserModel.findOne({accessToken: {$in: [accessToken]}}).exec();
    }

    static* logout(user, accessToken) {
        user.accessToken = user.accessToken.filter(token => {
            return token !== accessToken;
        });
        if (user.userDevicesData && user.userDevicesData[accessToken]) {
            delete user.userDevicesData[accessToken];
            user.markModified('userDevicesData');
        }
        return yield user.save();
    }

    static* addCourse(user, course) {
        user.courses.push(course);
        user.currency = course.currency;
        yield user.save();
    }

    static* editUserBalance(user, amount, type, transaction = null) {
        if (!user)
            throw new Error('User not found');
        if (Number(amount) < 0)
            throw new Error('Amount can\'t be < 0');
        // Start transaction
        const oldUserBalance = user.credits;
        let newUserBalance = user.credits;
        // Operation
        switch (type) {
            case editUserBalanceTypes.SUB :
                newUserBalance = Number(oldUserBalance) - Number(amount);
                break;
            case editUserBalanceTypes.ADD :
                newUserBalance = Number(oldUserBalance) + Number(amount);
                break;
            default:
                throw new Error('Method is not implementation for edit UserBalance');
        }
        user.credits = newUserBalance;
        yield Boolean(transaction) ? transaction.update('User', user.id, user) : user.save();
        return true;
        // End transaction
    }

    static* getUsersById(ids) {
        return yield UserModel.find({_id: {$in: ids}})
            .exec();
    }

    static* getUserById(id) {
        return yield UserModel.findOne({_id: {$eq: id}})
            .exec();
    }

    static* getUsersCount() {
        return yield UserModel.count({});
    }

    static* getUsersList(count, page) {
        const skip = Number(count) * (Number(page) - 1) >= 0 ? Number(count) * (Number(page) - 1) : 0;
        return yield UserModel.find({})
            .limit(Number(count))
            .sort({reports: -1})
            .sort({isDisabled: -1})
            .sort({name: 1})
            .skip(skip)
            .exec();
    }

    static* getMySessionIds(userId) {
        const user = yield UserModel.findOne({_id: {$eq: userId}})
            .populate('courses')
            .exec();
        const sessionIds = user.courses
            .reduce((sessionIds, course) => {
                return sessionIds.concat(...course.sessions.map((session) => {
                    return session.toString();
                }));
            }, []);
        return sessionIds;
    }

    static* disableUser(user, isEnable = false) {
        const newDisabledStatus = !isEnable;
        yield UserModel.update({_id: user._id}, {$set: {isDisabled: newDisabledStatus}});
        return yield UserModel.findOne({_id: user.id}).exec();
    }

    static* saveDeviceData(user, accessToken, body) {
        const {timezone, pushToken} = body;
        if (!user.userDevicesData)
            user.userDevicesData = {};

        if (!user.userDevicesData[accessToken])
            user.userDevicesData[accessToken] = {};

        user.userDevicesData[accessToken] = {
            pushToken
        };
        user.timezoneOffset = Number(timezone);
        return yield user.save();
    }

    static* reportUser(user) {
        return yield user.update({$inc: {reports: 1}}).exec();
    }

    static* isUserDisabled(dialCode, phoneNumber) {
        const user = yield UserModel.findOne({dialCode, phoneNumber}).exec();
        if (!user)
            return false;
        return user.isDisabled;
    }
}

module.exports = UserRepository;
