const moment = require('moment');

const Scheduler = require('./Scheduler');
const TaskFactory = require('./TaskFactory');
const {UPCOMING_SESSION_SMS} = require('../../constants/scheduleTaskTypes');

module.exports = {scheduleUpcomingSessionTask, cancelUpcomingSessionTask};

function scheduleUpcomingSessionTask(sessionModel) {
    const {startAt} = sessionModel;
    const task = TaskFactory.createUpcomingSessionTask(sessionModel);
    const startTimestamp = moment(startAt).subtract(15, 'minutes').unix();
    Scheduler.schedule(startTimestamp, task);
}

function cancelUpcomingSessionTask(sessionModel) {
    const taskId = TaskFactory.generateTaskId(UPCOMING_SESSION_SMS, sessionModel._id.toString());
    Scheduler.cancel(taskId);
}
