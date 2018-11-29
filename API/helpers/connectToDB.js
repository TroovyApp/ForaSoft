'use strict';

const mongoose = require('mongoose');
mongoose.Promise = global.Promise;

const config = require('../config');
const logger = require('../utils/logger');

class MongoConnector {
    constructor() {
        mongoose.connect(config.mongodb_server, {
            useMongoClient: true,
            reconnectTries: 5,
            reconnectInterval: 500
        })
            .then(() => {
                logger.log('Connecting to MongoDB');
            })
            .catch(error => {
                logger.error(error);
            });
    }
}

module.exports = new MongoConnector();
