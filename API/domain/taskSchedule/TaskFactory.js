const {UPCOMING_SESSION_SMS} = require('../../constants/scheduleTaskTypes');
const SendUpcomingNotificationTask = require('./tasks/SendUpcomingSmsNotification');

class TaskFactory {
    static createUpcomingSessionTask(sessionModel) {
        const taskId = TaskFactory.generateTaskId(UPCOMING_SESSION_SMS, sessionModel._id.toString());
        return new SendUpcomingNotificationTask(taskId, {sessionModel});
    }

    static generateTaskId(type, uniqueField) {
        return `${type}_${uniqueField}`;
    }
}

module.exports = TaskFactory;
