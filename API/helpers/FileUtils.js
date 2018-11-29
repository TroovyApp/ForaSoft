'use strict';

const fs = require('fs');
const path = require('path');

const PUBLIC_DIR = '../public';
const TEMP_DIR = PUBLIC_DIR + '/temp';
const UPLOAD_DIR = PUBLIC_DIR + '/uploads';

class FileUtils {
    static deleteFile(filePath) {
        const absoluteFilePath = filePath.indexOf(FileUtils.getPublicDir()) < 0
            ? FileUtils.resolvePublicPath(filePath)
            : filePath;
        return FileUtils._delete(absoluteFilePath);
    }

    static deleteTempFile(filePath) {
        const absoluteFilePath = filePath.indexOf(FileUtils.getTempDir()) < 0
            ? FileUtils.resolveTempPath(filePath)
            : filePath;
        return FileUtils._delete(absoluteFilePath);
    }

    static _delete(path) {
        return new Promise((resolve, reject) => {
            fs.unlink(path, err => {
                if (err) {
                    return reject(err);
                }
                return resolve();
            });
        });
    }

    static makeDir(path) {
        return new Promise((resolve, reject) => {
            fs.mkdir(path, err => {
                if (err)
                    return reject(err);
                return resolve();
            });
        });
    }

    static makeTempDir() {
        const tempDirPath = FileUtils.getTempDir();
        return FileUtils.makeDir(tempDirPath);
    }

    static isExist(path) {
        return new Promise(resolve => {
            fs.access(path, fs.constants.R_OK | fs.constants.W_OK, (err) => {
                resolve(!Boolean(err));
            });
        });
    }

    static resolvePublicPath(filePath) {
        const dir = filePath.indexOf('uploads') >= 0 ? PUBLIC_DIR : UPLOAD_DIR;
        return path.join(__dirname, dir, filePath);
    }

    static resolveTempPath(filePath) {
        return path.join(__dirname, TEMP_DIR, filePath);
    }

    static getTempDir() {
        return path.join(__dirname, TEMP_DIR);
    }

    static getUploadDir() {
        return path.join(__dirname, UPLOAD_DIR);
    }

    static getPublicDir() {
        return path.join(__dirname, PUBLIC_DIR);
    }

    static getRelativeUrl(filePath) {
        return path.sep + path.relative(FileUtils.getPublicDir(), filePath);
    }

    static deletePublicDir(dirName) {
        const dir = path.join(FileUtils.getUploadDir(), dirName);
        return FileUtils.removeDir(dir);
    }

    static removeDir(path) {
        return new Promise((resolve, reject) => {
            fs.rmdir(path, err => {
                if (err)
                    return reject(err);
                return resolve();
            });
        });
    }
}

module.exports = FileUtils;
