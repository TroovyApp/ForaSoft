'use strict';

const AbstractRoute = require('./AbstractRoute');

class StreamRoute extends AbstractRoute {
    constructor() {
        super();
        this.events = ['stream:info', 'stream:publish',
            'stream:play', 'stream:candidate',
            'stream:stop', 'stream:video:enable',
            'stream:video:disable',
            'stream:connected'
        ];
    }
}

module.exports = new StreamRoute();
