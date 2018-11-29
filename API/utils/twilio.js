const Twilio = require('twilio');

const config = require('../config');

module.exports = new Twilio(config.twilioAccountSid, config.twilioAuthToken);