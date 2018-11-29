'use strict';

const mongoose = require('mongoose');
const MongooseTransaction = require('mongoose-transaction')(mongoose);

class Transaction {
    constructor() {
        const transaction = new MongooseTransaction();
        this.transaction = transaction;
    }

    *run() {
        return this.transaction.run(function(err, docs){
        });
    }

    *rollback() {
        // auto rollback
        return true;
    }

    *update(modelName, findId, dataObj, options) {
        return this.transaction.update(modelName, findId, dataObj, options);
    }
}

module.exports = Transaction;
