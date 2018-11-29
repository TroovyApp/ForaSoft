'use strict';

const moment = require('moment');


module.exports = function (session) {
    const newSession = Object.assign({}, session);
    const startAt = moment.unix(session.startAt);
    newSession.startInfo = {
        datetime: startAt.format('llll'),
        month: startAt.format('MMM'),
        day: startAt.format('D'),
        time: startAt.format('hh:mm A')
    };
    return newSession;
};
