'use strict';

const co = require('co');

class UploadHandler {
    constructor() {
        this.processes = {};
    }

    handle(generator, id) {
        const promise = new Promise((resolve, reject) => {
            co(generator).then(result => {
                resolve(result);
            }).catch(err => {
                reject(err);
            });
        });
        this.processes[id] = promise;
        return promise;
    }

    unhandle(id) {
        delete this.processes[id];
    }

    get(id) {
        return this.processes[id];
    }
}

module.exports = new UploadHandler();
