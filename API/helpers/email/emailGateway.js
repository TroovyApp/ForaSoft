const nodemailer = require('nodemailer');
const {promisify} = require('es6-promisify');

const config = require('../../config');

const transport = nodemailer.createTransport(config.mailTransport);

module.exports = {
    sendMail: function* (options) {
        console.log(`Email rendered`);
        const send = promisify(transport.sendMail.bind(transport));
        return yield send(options);
    }
};
