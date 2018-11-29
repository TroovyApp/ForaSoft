'use strict';

module.exports = file => {
    return file ? '/uploads/' + file.filename : '';
};
