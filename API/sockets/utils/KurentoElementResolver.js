'use strict';

const _wrap = require('../../utils/kurentoWrapper');


class KurentoElementResolver {
    setConnectionPromise(promise) {
        this.kurentoConnectionPromise = promise;
    }

    create(name) {
        return this.kurentoConnectionPromise.then(c => _wrap(c.create(name)));
    }

    load(id) {
        return this.kurentoConnectionPromise.then(c => _wrap(c.getMediaobjectById(id)));
    }
}

module.exports = new KurentoElementResolver();
