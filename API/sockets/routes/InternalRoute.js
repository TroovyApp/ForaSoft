'use strict';

const EventEmitter = require('events');

class InternalRoute extends EventEmitter{
    constructor() {
        super();
    }
}

module.exports = new InternalRoute();
