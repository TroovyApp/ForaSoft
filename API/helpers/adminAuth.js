'use strict';

const wrap = require('co').wrap;

const accessDeniedError = require('../helpers/apiError').accessDeniedError;

module.exports = wrap(function*(req, res, next) {
    if (!req.session.isAdmin) {
        res.cookie('isAuth', '0');
        return res.send(accessDeniedError());
    }
    return next();
});
