module.exports = function (req, file, cb) {
    const mimetype = file.mimetype;
    switch (mimetype) {
        case 'image/jpeg':
        case 'image/png':
            cb(null, true);
            break;
        default:
            cb(null, false);
            break;
    }
};
