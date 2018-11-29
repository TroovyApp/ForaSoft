const multer = require('multer');
const storage = require('./fileStorage');
const fileFilter = require('./imageFileFilter');

const upload = multer({storage: storage, fileFilter: fileFilter});

module.exports = function (field) {
    return function (req, res, next) {
        upload.single(field)(req, res, function () {
            return next();
        });
    };
};