'use strict';

module.exports = (eventEmitter)=> {
    return new Promise((resolve, reject)=> {
        eventEmitter
            .once('finish', resolve)
            .once('error', reject);
    });
};
