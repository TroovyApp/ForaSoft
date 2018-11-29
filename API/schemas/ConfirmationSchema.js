const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const ConfirmationSchema = new Schema({
    dialCode: String,
    phoneNumber: String,
    appGeneratedToken: {type: String, unique: true, required: true},
    confirmationCode: String,
    isVerified: {type: Boolean, default: false}
}, {collection: 'Confirmation'});

module.exports = mongoose.model('Confirmation', ConfirmationSchema);
