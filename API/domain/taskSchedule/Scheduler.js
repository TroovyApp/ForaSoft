const _scheduler = require('node-schedule');
const moment = require('moment');
const co = require('co');

class Scheduler {
    constructor() {
        this.jobs = {};
    }

    schedule(timestamp, task) {
        const rule = timestampToRule(timestamp);
        this.jobs[task.id] = _scheduler.scheduleJob(rule, () => {
            doTask(task);
        });
    }

    cancel(id) {
        const job = this.jobs[id];
        if (!job)
            return;

        job.cancel();
        delete this.jobs[id];
    }

    isScheduled(id) {
        return Boolean(this.jobs[id]);
    }
}

module.exports = new Scheduler();

function doTask(task) {
    co(task.run());
}

function timestampToRule(timestamp) {
    const date = moment.unix(timestamp);
    const rule = new _scheduler.RecurrenceRule();
    rule.dayOfWeek = date.day();
    rule.hour = date.hours();
    rule.minute = date.minutes();
    rule.second = date.second();
    return rule;
}
