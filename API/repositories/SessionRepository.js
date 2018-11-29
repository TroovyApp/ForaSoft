'use strict';

const moment = require('moment');

const SessionModel = require('../schemas/SessionsSchema');
const AttachmentModel = require('../schemas/AttachmentSchema');
const CourseModel = require('../schemas/CourseSchema');

const fromMinutesToSeconds = require('../utils/fromMinutesToSeconds');
const logger = require('../utils/logger');

class SessionRepository {
    static* createSession(course, title, description, duration, startAt) {
        return yield SessionModel.create({
            course,
            title,
            description,
            duration,
            startAt: moment.unix(startAt).valueOf()
        });
    }

    static* isSessionTimeValid(user, startAt, duration, sessionId) {
        const currentTime = moment().utc().unix();
        const endAt = Number(startAt) + fromMinutesToSeconds(duration);

        logger.log(`Try to create session with startAt 
        ${startAt} and duration ${duration} 
        and endAt ${endAt}
        for user ${user._id.toString()}. Current timestamp ${currentTime}`);

        if (currentTime > startAt) {
            logger.log('Session is in past');
            return false;
        }

        const upcomingSessions = yield CourseModel.getUpcomingSessions(user, true);
        const sessionsWithSameTime = upcomingSessions
            .filter(session => {
                if (sessionId && session._id.toString() === sessionId.toString())
                    return false;

                const sessionTimestamp = moment(session.startAt).utc().unix();
                const sessionEndAt = sessionTimestamp + fromMinutesToSeconds(session.duration);
                return !(endAt <= sessionTimestamp || sessionEndAt <= startAt);
            });
        logger.log(`Cross with ${sessionsWithSameTime.length} sessions`);
        sessionsWithSameTime.forEach(session => {
            logger.log(`Session id ${session._id.toString()}`);
            logger.log(`Timestamp ${moment(session.startAt).utc().unix()}`);
        });
        return sessionsWithSameTime.length === 0;
    }

    static* findSession(sessionId, user) {
        const session = yield SessionModel.findOne({_id: sessionId}).populate({
            path: 'course'
        }).exec();

        if (!user)
            return session;

        if (!session)
            return;

        if (session.course.creator.toString() != user._id.toString())
            return;

        return session;
    }

    static* findSessionForRemoving(sessionId, user) {
        const session = yield SessionModel.findOne({_id: sessionId})
            .populate('course')
            .exec();

        if (!user)
            return session;

        if (!session)
            return;

        if (session.course.creator.toString() !== user._id.toString())
            return;

        return session;
    }

    static* editSession(sessionId, qualities) {
        yield SessionModel.update({_id: sessionId}, {$set: qualities});
        return yield SessionModel.findOne({_id: sessionId}).exec();
    }

    static* deleteSession(user, sessionId) {
        const session = yield this.findSessionForRemoving(sessionId, user);
        yield session.populate({
            path: 'course',
            populate: {
                path: 'subscribers'
            }
        }).execPopulate();
        if (!session)
            return;
        yield session.remove();
        return session;
    }

    static* findSessionAttachments(session) {
        /** Temp method. Returned all course attachment */
        const attachments = yield AttachmentModel.find({course: session.course}).exec();
        return attachments.filter(attachment => {
            return Object.keys(attachment.params).length > 0;
        });
    }
}

module.exports = SessionRepository;
