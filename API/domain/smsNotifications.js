const moment = require('moment');
const {sprintf} = require('sprintf-js');

const twilioClient = require('../utils/twilio');
const branch = require('../helpers/BranchRequestHelper');

const logger = require('../utils/logger');
const config = require('../config');

module.exports = {sendUpcomingSessionNotification, sendCancelSessionNotification, sendNewSessionNotification};

function* sendUpcomingSessionNotification(sessionModel) {
    const template = 'Your session is going to start in 15 min. Don’t miss it: %s';
    yield sessionModel.populate({
        path: 'course',
        populate: {
            path: 'subscribers'
        }
    }).execPopulate();
    const text = yield addLinkToText(template, sessionModel);
    yield sendNotificationToSubscribers(sessionModel, text);
    yield sendNotificationToCreator(sessionModel, text);
}

function* sendCancelSessionNotification(sessionModel) {
    const text = `Sorry, the workshop session at %s was cancelled.  We will keep you updated.`;
    yield sendNotificationToSubscribers(sessionModel, text, formatCancelledSessionText);
}

function formatCancelledSessionText(text, sessionModel, user) {
    const utcOffset = getReadableUTCOffset(user.timezoneOffset);
    const sessionDate = moment.utc(sessionModel.startAt).utcOffset(user.timezoneOffset / 60).format('HH:mm MM/DD/YYYY ');
    return sprintf(text, `${sessionDate} ${utcOffset}`);
}

function getReadableUTCOffset(timezoneOffset) {
    const hours = Math.floor(Math.abs(timezoneOffset) / 3600);
    const hoursString = hours < 10 ? '0' + hours : hours;
    const minutes = (Math.floor(Math.abs(timezoneOffset) / 60)) - hours * 60;
    const minutesString = minutes < 10 ? '0' + minutes : minutes;
    const sign = timezoneOffset < 0 ? '-' : '+';
    return `(UTC ${sign}${hoursString}:${minutesString})`;
}

function* sendNewSessionNotification(sessionModel) {
    const template = 'A new session was added to your workshop! Check the workshop schedule here - %s';
    yield sessionModel.populate({
        path: 'course',
        populate: {
            path: 'subscribers'
        }
    }).execPopulate();

    const text = yield addLinkToText(template, sessionModel);
    yield sendNotificationToSubscribers(sessionModel, text);
}

function* addLinkToText(text, sessionModel) {
    yield sessionModel.course.populate('intro').execPopulate();
    const courseDTO = sessionModel.course.toShortDTO();
    const imageURL = courseDTO.courseImageSharingUrl;
    const link = yield branch.createLink(courseDTO.id, courseDTO.title, courseDTO.description, courseDTO.webPage, imageURL);
    return sprintf(text, link);
}

function* sendNotification(phoneNumber, text) {
    try {
        return yield twilioClient.messages.create({
            to: phoneNumber,
            body: text,
            from: config.twilioPhoneNumber
        });
    } catch (err) {
        logger.log(`[Send notification error]: ${err.stack}`)
    }
}

function* sendNotificationToSubscribers(sessionModel, text, formatter) {
    yield sessionModel.course.subscribers.map(user => {
        const personalizedText = formatter ? formatter(text, sessionModel, user) : text;
        const phoneNumber = user.dialCode + user.phoneNumber;
        return sendNotification(phoneNumber, personalizedText);
    });
}

function* sendNotificationToCreator(sessionModel, text, formatter) {
    yield sessionModel.course.populate('creator').execPopulate();
    const creator = sessionModel.course.creator;
    const personalizedText = formatter ? formatter(text, sessionModel, creator) : text;
    const phoneNumber = creator.dialCode + creator.phoneNumber;
    return yield sendNotification(phoneNumber, personalizedText);
}
