'use strict';

const co = require('co');

const {ensureTaskScheduled} = require('../domain/taskSchedule/startHook');
const {ensureMiniThumbnailCreated} = require('../helpers/imageMiniThumbnailStartHook');
const {ensureCurrencyAdded} = require('../helpers/currencyStartHook');

function* run() {
    yield ensureTaskScheduled();
    yield ensureMiniThumbnailCreated();
    yield ensureCurrencyAdded();
}

module.exports = co(run());
