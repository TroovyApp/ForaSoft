'use strict';

const AbstractRoute = require('./AbstractRoute');

class SessionRoute extends AbstractRoute {
    constructor() {
        super();
        this.events = ['session:join', 'session:leave'];
    }
}

module.exports = new SessionRoute();
