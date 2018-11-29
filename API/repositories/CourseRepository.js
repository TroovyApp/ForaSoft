'use strict';

const moment = require('moment');

const CourseModel = require('../schemas/CourseSchema');
const STATUS = require('../constants/courseStatus');
const deleteCourseIntroHelper = require('../helpers/deleteCourseIntro');

function getSubscribedQuery(userId) {
    return {
        status: {$in: [STATUS.COURSE_PUBLISHED, STATUS.COURSE_ARCHIVED]},
        subscribers: {$in: [userId]},
        tier: {$exists: true}
    };
}

function getFeaturedQuery(userId) {
    return {
        status: {$in: [STATUS.COURSE_PUBLISHED, STATUS.COURSE_ARCHIVED]},
        tier: {$exists: true},
        creator: {$ne: userId},
        subscribers: {$nin: [userId]}
    };
}

function getOwnQuery(userId) {
    return {creator: userId, tier: {$exists: true}};
}

class CourseRepository {
    static* getCourseList(user, count, page, withoutMyCourses, isSubscribed, UserId = '') {
        if (!user)
            return;
        let query = {};

        if (Boolean(UserId)) {
            query = {creator: UserId, tier: {$exists: true}}
        } else {
            const userId = user._id.toString();

            if (withoutMyCourses && !isSubscribed)
                query = getFeaturedQuery(userId);

            if (withoutMyCourses && isSubscribed)
                query = getSubscribedQuery(userId);

            if (!withoutMyCourses && !isSubscribed)
                query = getOwnQuery(userId);
        }

        const skip = Number(count) * (Number(page) - 1) >= 0 ? Number(count) * (Number(page) - 1) : 0;
        return yield CourseModel.find(query)
            .limit(Number(count))
            .skip(skip)
            .populate('sessions')
            .exec();
    }

    static* getCoursesCount() {
        return yield CourseModel.count({});
    }

    static* getCourseListForAdmin(count, page) {
        const skip = Number(count) * (Number(page) - 1) >= 0 ? Number(count) * (Number(page) - 1) : 0;
        return yield CourseModel.find({})
            .sort({title: 1})
            .limit(Number(count))
            .skip(skip)
            .populate('sessions')
            .populate('creator')
            .populate('intro')
            .populate('subscribers')
            .exec();
    }

    static* createCourse(user, title, description, price, tier, status, courseImageUrl, currency) {
        console.log(`Create course for ${user._id} with parameters ${title} ${description} ${price} ${tier} ${status} ${currency}`);
        return yield CourseModel.create({
            creator: user._id,
            title,
            description,
            price,
            status,
            tier,
            courseImageUrl,
            currency
        });
    }

    static* getCourseInfoForOwner(courseId, userId) {
        return yield CourseModel.findOne({_id: courseId, creator: userId})
            .populate('creator')
            .populate('sessions')
            .populate('intro')
            .exec();
    }

    static* getCourseInfoForNotOwner(courseId) {
        return yield CourseModel.findOne({
            _id: courseId,
            status: {$in: [STATUS.COURSE_PUBLISHED, STATUS.COURSE_ARCHIVED]}
        }).populate('creator')
            .populate('sessions')
            .populate('intro')
            .exec();
    }

    static* getCoursesByIds(ids) {
        return yield CourseModel.find({_id: {$in: ids}})
            .populate('creator')
            .populate('sessions')
            .populate('intro')
            .exec();
    }

    static* getCourseForEditing(user, courseId) {
        return yield CourseModel.findOne({
            _id: courseId,
            creator: user,
            status: {$in: [STATUS.COURSE_PUBLISHED, STATUS.COURSE_UNPUBLISHED]}
        }).populate('sessions').exec();
    }

    static* updateCourse(course, qualities) {
        yield CourseModel.update({_id: course._id}, {$set: qualities});
        return yield CourseModel.findOne({_id: course.id}).populate('sessions').populate('intro').exec();
    }

    static* findCourse(courseId) {
        return yield CourseModel.findOne({_id: courseId}).populate('sessions').exec();
    }

    static* findCourseForRemoving(courseId, user) {
        const course = yield CourseModel.findOne({_id: courseId})
            .populate('creator')
            .populate('sessions')
            .populate('attachments')
            .exec();

        if (!user)
            return course;

        if (!course)
            return;

        if (course.creator._id.toString() !== user._id.toString())
            return;

        return course;
    }

    static* getCourseForSubscribing(user, courseId) {
        return yield CourseModel.findOne({
            _id: courseId,
            creator: {$ne: user},
            subscribers: {$nin: [user.id]},
            status: STATUS.COURSE_PUBLISHED
        }).populate('creator');
    }

    static* findUpcomingSessions(user) {
        const upcomingSessions = yield CourseModel.getUpcomingSessions(user);
        return upcomingSessions.map(session => {
            const course = session.course;
            return {
                id: session._id,
                title: session.title,
                description: session.description,
                duration: session.duration,
                courseId: session.course._id.toString(),
                startAt: moment(session.startAt).unix(),
                createdAt: moment(session.createdAt).unix(),
                updatedAt: moment(session.updatedAt).unix(),
                creatorId: course.creator
            };
        });
    }

    static* getSomeUpcomingSessionTimeStatus(courseId, status) {
        const course = yield CourseModel.findOne({_id: courseId}).populate('creator').exec();
        const user = course.creator;
        const upcomingSessions = yield CourseModel.getUpcomingSessions(user, true);
        return upcomingSessions.some((session) => {
            return session.timeStatus === status && session.course._id.toString() === courseId;
        });
    }

    static* deleteCourse(user, courseId) {
        const course = yield this.findCourseForRemoving(courseId, user);
        if (!course)
            return;
        return yield course.remove();
    }

    static* isCurrencyEqual(user, currency) {
        if (user.currency === currency)
            return true;

        if (user.currency !== currency && user.credits !== 0)
            return false;

        const courses = yield CourseModel.find({currency: {$ne: currency}}).exec();
        return courses.length === 0;
    }
}

module.exports = CourseRepository;
