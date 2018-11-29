const multer = require('multer');
const storage = require('./tempFileStorage');

const upload = multer({storage: storage});

module.exports = function (field) {
    return function (req, res, next) {
        upload.single(field)(req, res, function () {
            return next();
        });
    };
};