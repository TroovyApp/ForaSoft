'use strict';

const EventEmitter = require('events');

class Command extends EventEmitter {
    constructor(dataId) {
        super();
        this.type = null;
        this.dataId = dataId;
    }

    getType() {
        return this.type;
    }

    finish() {
        this.emit('finish');
    }

    error(err) {
        this.emit('error', err);
    }
}

module.exports = Command;
