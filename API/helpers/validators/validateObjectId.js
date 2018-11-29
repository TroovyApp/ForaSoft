'use strict';

const ID_REGEXP = new RegExp(/^[0-9a-fA-F]{24}$/);

module.exports = (id) => {
    return id.match(ID_REGEXP);
};
