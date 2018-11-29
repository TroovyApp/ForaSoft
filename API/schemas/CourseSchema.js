const mongoose = require('mongoose');
const moment = require('moment');
const Schema = mongoose.Schema;

const moneyUtils = require('../utils/money');
const getAbsoluteLink = require('../utils/getAbsoluteLink');

const STATUS = require('../constants/courseStatus');
const COURSES_SORT_MODS = require('../constants/courseSortMods');
const UPLOADING_TYPES = require('../constants/uploadingDataConstants').uploadingDataTypes;

const LIVE_SESSIONS_STATUS = require('../constants/sessionConstants').liveSessionStatus;
const TIME_STATUS = require('../constants/timeStatus');

const config = require('../config');


const CourseSchema = new Schema({
    title: String,
    description: String,
    status: {type: Number, default: STATUS.COURSE_UNPUBLISHED},
    price: {type: Number, default: 0},
    rawIncome: {type: Number, default: 0},
    tier: {type: String},
    earnings: {type: Number, default: 0},
    courseImageUrl: String,
    courseIntroVideoUrl: String,
    courseIntroVideoPreviewUrl: String,
    creator: {type: Schema.ObjectId, ref: 'User'},
    subscribers: [{type: Schema.ObjectId, ref: 'User', default: []}],
    sessions: [{type: Schema.ObjectId, ref: 'Session', default: []}],
    attachments: [{type: Schema.ObjectId, ref: 'Attachment', default: []}],
    intro: [{type: Schema.ObjectId, ref: 'Intro', default: []}],
    currency: {type: String},
    createdAt: {type: Date},
    updatedAt: {type: Date}
}, {collection: 'Course', usePushEach: true});

CourseSchema.pre('save', function (next) {
    if (!this.createdAt)
        this.createdAt = moment().utc().valueOf();
    this.updatedAt = moment().utc().valueOf();
    next();
});

CourseSchema.pre('update', function (next) {
    this.update({}, {$set: {updatedAt: moment().utc().valueOf()}});
    next();
});

CourseSchema.pre('remove', function (next) {
    this.sessions.map((session) => {
        if (Boolean(session.remove) && typeof session.remove === 'function')
            return session.remove();
    });
    this.attachments.map((attachment) => {
        if (Boolean(attachment.remove) && typeof attachment.remove === 'function')
            return attachment.remove();
    });
    next();
});

CourseSchema.methods.toDTO = function (user) {
    const media = getCourseMedia(this);

    return {
        id: this._id,
        title: this.title,
        description: this.description,
        status: this.status,
        courseImageUrl: media.courseImageUrl,
        courseImageSharingUrl: media.courseImageSharingUrl,
        courseIntroVideoUrl: media.courseIntroVideoUrl,
        courseIntroVideoPreviewUrl: media.courseIntroVideoPreviewUrl,
        intro: media.intro,
        price: this.price,
        currency: this.currency,
        tier: this.tier,
        creatorId: this.creator._id ? this.creator._id.toString() : this.creator.toString(),
        creatorName: Boolean(this.creator.name) ? this.creator.name : this.creator,
        sessions: this.sessions.map((session) => {
            return session.toDTO();
        }),
        subscribed: Boolean(user) ? this.getSubscribed(user) : false,
        webPage: this.getLink(),
        earnings: this.earnings,
        nearestSessionAt: this.getNearestSessionAt(),
        subscribersCount: this.subscribers && Array.isArray(this.subscribers) ? this.subscribers.length : 0,
        createdAt: moment(this.createdAt).unix(),
        updatedAt: moment(this.updatedAt).unix()
    }
};

CourseSchema.methods.toListDTO = function (sortMod = COURSES_SORT_MODS.COURSE_CREATE) {
    return {
        id: this._id,
        nearestSessionAt: this.getNearestSessionAt(),
        createdAt: moment(this.createdAt).unix(),
        updatedAt: moment(this.updatedAt).unix(),
        subscribersCount: this.subscribers && Array.isArray(this.subscribers) ? this.subscribers.length : 0,
        sortBy: this.getSortBy(sortMod)
    }
};

CourseSchema.methods.toNotOwnerDTO = function (user) {
    const media = getCourseMedia(this);
    return {
        id: this._id,
        title: this.title,
        description: this.description,
        status: this.status,
        tier: this.tier,
        courseImageUrl: media.courseImageUrl,
        courseImageSharingUrl: media.courseImageSharingUrl,
        courseIntroVideoUrl: media.courseIntroVideoUrl,
        courseIntroVideoPreviewUrl: media.courseIntroVideoPreviewUrl,
        price: this.price,
        currency: this.currency,
        creatorId: this.creator._id ? this.creator._id.toString() : this.creator.toString(),
        creatorName: Boolean(this.creator.name) ? this.creator.name : this.creator,
        sessions: this.sessions.map((session) => {
            return session.toDTO();
        }),
        subscribed: Boolean(user) ? this.getSubscribed(user) : false,
        webPage: this.getLink(),
        nearestSessionAt: this.getNearestSessionAt(),
        intro: media.intro,
        subscribersCount: this.subscribers && Array.isArray(this.subscribers) ? this.subscribers.length : 0,
        createdAt: moment(this.createdAt).unix(),
        updatedAt: moment(this.updatedAt).unix(),
        subscribers: this.subscribers
    };
};

CourseSchema.methods.toShortDTO = function (user) {
    const media = getCourseMedia(this);
    return {
        id: this._id,
        title: this.title,
        description: this.description,
        courseImageUrl: media.courseImageUrl,
        courseImageSharingUrl: media.courseImageSharingUrl,
        courseIntroVideoPreviewUrl: media.courseIntroVideoPreviewUrl,
        creatorName: Boolean(this.creator.name) ? this.creator.name : this.creator,
        webPage: this.getLink(),
        subscribed: Boolean(user) ? this.getSubscribed(user) : false,
        nearestSessionAt: this.getNearestSessionAt(),
        createdAt: moment(this.createdAt).unix(),
        updatedAt: moment(this.updatedAt).unix(),
        price: this.price,
        currency: this.currency,
        tier: this.tier,
        subscribersCount: this.subscribers && Array.isArray(this.subscribers) ? this.subscribers.length : 0
    }
};

CourseSchema.methods.toAdminDTO = function (sortMod = COURSES_SORT_MODS.COURSE_CREATE) {
    const media = getCourseMedia(this);
    return {
        id: this._id,
        title: this.title,
        description: this.description,
        courseImageUrl: media.courseImageUrl,
        courseIntroVideoPreviewUrl: media.courseIntroVideoPreviewUrl,
        courseImageSharingUrl: media.courseImageSharingUrl,
        creatorName: Boolean(this.creator.name) ? this.creator.name : this.creator,
        creator: this.creator.toInfo(),
        webPage: this.getLink(),
        sessions: this.sessions.map((session) => {
            return session.toDTO();
        }),
        status: this.status,
        price: this.price,
        currency: this.currency,
        nearestSessionAt: this.getNearestSessionAt(),
        createdAt: moment(this.createdAt).unix(),
        updatedAt: moment(this.updatedAt).unix(),
        sortBy: this.getSortBy(sortMod),
        subscribersCount: this.subscribers && Array.isArray(this.subscribers) ? this.subscribers.length : 0,
        subscribers: this.subscribers.map(s => {
            return {
                name: s.name,
                imageUrl: Boolean(s.imageUrl) ? s.imageUrl : ''
            };
        }),
        rawIncome: this.rawIncome
    }
};

const getCourseMedia = course => {
    const media = {};
    media.intro = course.intro
        .filter(intro => {
            return Boolean(intro.fileUrl);
        })
        .sort((a, b) => {
            if (a.order !== b.order)
                return a.order > b.order ? 1 : -1;
            return a.updatedAt > b.updatedAt ? 1 : -1;
        }).map(intro => {
            return intro.toDTO();
        });
    media.courseImageUrl = '';
    media.courseIntroVideoUrl = '';
    media.courseIntroVideoPreviewUrl = '';
    media.courseImageSharingUrl = '';
    for (let i = 0; i < media.intro.length; i++) {
        if (media.intro[i].type === UPLOADING_TYPES.INTRO_IMAGE) {
            media.courseImageUrl = media.intro[i].fileUrl;
            media.courseImageSharingUrl = media.intro[i].fileSharingUrl
                ? config.host + media.intro[i].fileSharingUrl
                : '';
            break;
        }
    }
    for (let i = 0; i < media.intro.length; i++) {
        if (media.intro[i].type === UPLOADING_TYPES.INTRO_VIDEO) {
            media.courseIntroVideoUrl = media.intro[i].fileUrl;
            media.courseIntroVideoPreviewUrl = media.intro[i].fileThumbnailUrl;
            media.courseImageSharingUrl = media.intro[i].fileSharingUrl
                ? config.host + media.intro[i].fileSharingUrl
                : '';
            media.courseImageUrl = '';
            break;
        }
    }
    return media;
};

CourseSchema.methods.subscribe = function (user, earnings, rawIncome) {
    this.subscribers.addToSet(user);
    this.earnings = Number(moneyUtils.roundMoney(Number(this.earnings) + Number(earnings)));
    this.rawIncome = Number(moneyUtils.roundMoney(Number(this.rawIncome) + Number(rawIncome)));
    return this;
};

CourseSchema.methods.getLink = function () {
    return getAbsoluteLink("/courses/") + this._id;
};

CourseSchema.methods.getNearestSessionAt = function () {
    const defaultValue = -1;
    if (Array.isArray(this.sessions) && this.sessions.length > 0) {
        // find min value sessions.startAt
        return this.sessions.map(function (session) {
            return moment(session.startAt).unix()
        }).sort(function (a, b) {
            return a - b;
        })[0];
    }
    return defaultValue;
};

CourseSchema.methods.getSortBy = function (sortMod) {
    switch (Number(sortMod)) {
        case COURSES_SORT_MODS.COURSE_CREATE :
            return moment(this.createdAt).unix();
            break;
        case COURSES_SORT_MODS.COURSE_UPDATE :
            return moment(this.updatedAt).unix();
            break;
        case COURSES_SORT_MODS.COURSE_NEAREST_SESSION :
            return this.getNearestSessionAt();
            break;
        case COURSES_SORT_MODS.COURSE_TITLE :
            return this.title;
            break;
        default :
            return moment(this.createdAt).unix();
            break;
    }
};

CourseSchema.methods.getSubscribed = function (user) {
    return this.subscribers.some((subscriber) => {
        return subscriber.equals(user._id) && !(subscriber.equals(this.creator._id));
    });
};

CourseSchema.statics.getUpcomingSessions = function* (user, isOnlyOwn) {
    const query = isOnlyOwn ? {creator: user} : {
        $or: [{creator: user}, {subscribers: {$in: [user]}, status: STATUS.COURSE_PUBLISHED}]
    };
    const courses = yield this.find(query).populate('sessions').exec();

    let sessions = [];
    courses.forEach(course => {
        sessions = sessions.concat(course.sessions);
    });

    let upcomingSessions = sessions.filter(session => {
        return session.timeStatus !== TIME_STATUS.FINISHED;
    });

    // Get finished live sessions
    const finishedLiveSessions = yield this.model('LiveSession').find({
        session: {$in: upcomingSessions},
        status: LIVE_SESSIONS_STATUS.FINISHED
    }).exec();

    // remove finished live sessions from upcoming sessions
    upcomingSessions = upcomingSessions.filter(session => {
        return finishedLiveSessions.every((liveSession) => {
            return liveSession.session.toString() !== session._id.toString();
        });
    });

    yield upcomingSessions.map(session => {
        return session.populate('course').execPopulate();
    });

    return upcomingSessions;
};

module.exports = mongoose.model('Course', CourseSchema);
