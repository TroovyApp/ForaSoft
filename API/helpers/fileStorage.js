const multer = require('multer');
const path = require('path');

const FileUtils = require('./FileUtils');

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, FileUtils.getUploadDir());
    },
    filename: function (req, file, cb) {
        const rnd = Math.random().toString(36).slice(2);
        cb(null, file.fieldname + '-' + rnd + '-' + Date.now() + path.extname(file.originalname));
    }
});

module.exports = storage;
