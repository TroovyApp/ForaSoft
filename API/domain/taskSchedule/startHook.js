const moment = require('moment');

const SessionModel = require('../../schemas/SessionsSchema');
const {scheduleUpcomingSessionTask} = require('./taskManagement');

module.exports = {ensureTaskScheduled};

function* ensureTaskScheduled() {
    const now = moment().utc().add(15, 'minutes');
    const sessions = yield SessionModel.find({
        startAt: {
            $gte: now.toDate()
        }
    }).exec();
    sessions.forEach(c => scheduleUpcomingSessionTask.call(undefined, c));
}
