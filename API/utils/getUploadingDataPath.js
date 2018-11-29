'use strict';

const randToken = require('rand-token');
const path = require('path');

const FileUtils = require('../helpers/FileUtils');

function getPath(entityId, ext) {
    return new Promise((resolve, reject) => {
        const path = FileUtils.resolvePublicPath(entityId);
        return FileUtils.isExist(path)
            .then(isExist => _makeDirIfNeeded(!isExist, path))
            .then(() => _formatPath(path, ext))
            .then(path => resolve(path))
            .catch(err => reject(err));
    });
}

function _makeDirIfNeeded(isNeed, path) {
    return isNeed ? FileUtils.makeDir(path) : null;
}

function _formatPath(dir, ext) {
    return path.join(dir, randToken.generate(32) + ext);
}

module.exports = getPath;
