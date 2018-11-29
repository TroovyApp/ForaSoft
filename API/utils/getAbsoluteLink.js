const config = require('../config');

'use strict';

module.exports = (path) => {
    return config.host + path;
};
