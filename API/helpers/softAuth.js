'use strict';

const wrap = require('co').wrap;

const UserRepository = require('../repositories/UserRepository');

const userDisabledError = require('../helpers/apiError').userDisabledError;

module.exports = wrap(function*(req, res, next) {
    if (req.user) {
        return next();
    }
    const {accessToken} = req.query;
    if (!accessToken)
        return next();

    const user = yield UserRepository.findByAccessToken(accessToken);
    if (!user)
        return next();

    if (user.isDisabled) {
        return res.send(userDisabledError());
    }
    req.user = user;
    return next();
});