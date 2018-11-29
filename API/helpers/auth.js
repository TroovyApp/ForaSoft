'use strict';

const wrap = require('co').wrap;

const UserRepository = require('../repositories/UserRepository');

const accessDeniedError = require('../helpers/apiError').accessDeniedError;
const userDisabledError = require('../helpers/apiError').userDisabledError;

module.exports = wrap(function*(req, res, next) {
    if (req.user) {
        return next();
    }
    const {accessToken} = req.query;
    if (!accessToken)
        return res.send(accessDeniedError());

    const user = yield UserRepository.findByAccessToken(accessToken);
    if (!user)
        return res.send(accessDeniedError());

    if (user.isDisabled) {
        return res.send(userDisabledError());
    }
    req.user = user;
    return next();
});
