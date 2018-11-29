'use strict';

const config = require('../config');

const validationError = require('../helpers/apiError').validationError;
const serverServiceError = require('../helpers/apiError').serverServiceError;

const loginAdmin = function*(req) {
    if (!Boolean(config.adminProfile)) {
        throw serverServiceError('Administrator not created');
    }
    const adminEmail = config.adminProfile.email;
    if (!Boolean(adminEmail)) {
        throw serverServiceError('Administrator\'s email not exists');
    }
    const adminPassword = config.adminProfile.password;
    if (!Boolean(adminPassword)) {
        throw serverServiceError('Administrator\'s password not exists');
    }

    const {email, password} = req.body;

    if (email === adminEmail && password === adminPassword) {
        req.session.isAdmin = 1;
        return true;
    }
    else {
        req.session.isAdmin = 0;
        throw validationError('Invalid email or password');
    }
};

const logoutAdmin = function*(req) {
    req.session.isAdmin = 0;
    return true;
};

module.exports = {
    loginAdmin,
    logoutAdmin
};
