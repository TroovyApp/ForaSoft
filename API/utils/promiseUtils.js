'use strict';

module.exports = {
    makeCallback() {
        let callback;

        const promise = new Promise((resolve, reject) => {
            callback = function (error, result) {
                if (error)
                    return reject(error);

                return resolve(result);
            };
        });

        callback.promise = promise;

        return callback;
    },

    extractPromisesQueue(queue) {
        let promise = Promise.resolve();
        queue.forEach((task) => {
            promise = promise.then(() => {
                return new Promise(task);
            });
        });
        return promise;
    }
};
