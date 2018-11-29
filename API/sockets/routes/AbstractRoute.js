'use strict';

const EventEmitter = require('events');

class AbstractRoute extends EventEmitter {
    constructor() {
        super();
        this.events = [];
    }

    listen(socket) {
        this.events.forEach(event => {
            socket.on(event, (data, callback) => {
                this.emit(event, socket, data, callback);
            });
        });
        socket.on('disconnect', () => {
            this.emit('release', socket)
        });
    }
}

module.exports = AbstractRoute;
