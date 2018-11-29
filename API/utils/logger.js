'use strict';

exports.log = message => {
    console.log('[' + new Date().toString() + ']: ' + message);
};

exports.error = error => {
    console.log('[' + new Date().toString() + ']: ' + error);
};
