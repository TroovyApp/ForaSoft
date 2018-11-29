const Task = require('./Task');
const {sendUpcomingSessionNotification} = require('../../smsNotifications');

class SendUpcomingNotificationTask extends Task {
    * run() {
        const {sessionModel} = this.params;
        yield sendUpcomingSessionNotification(sessionModel);
    }
}

module.exports = SendUpcomingNotificationTask;
