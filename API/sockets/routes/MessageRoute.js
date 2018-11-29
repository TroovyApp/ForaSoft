'use strict';

const AbstractRoute = require('./AbstractRoute');

class MessageRoute extends AbstractRoute {
    constructor() {
        super();
        this.events = ['message:send'];
    }
}

module.exports = new MessageRoute();
