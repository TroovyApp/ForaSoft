'use strict';

module.exports = (o, keys) => {
    const result = {};

    keys.forEach(key => {
        if (key in o)
            result[key] = o[key];
    });

    return result;
};
