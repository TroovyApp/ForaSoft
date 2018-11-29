'use strict';

const IntroModel = require('../schemas/IntroSchema');

class IntroRepository {
    static* createIntro(course, type, order) {
        const intro = yield IntroModel.create({type, order, course});
        yield course.intro.addToSet(intro);
        yield course.save();
        return intro;
    }


    static* getIntro(user, introId, type) {
        const query = Boolean(type) ? {_id: introId, type} : {_id: introId};
        const intro = yield IntroModel.findOne(query).populate('course').exec();
        if (!intro)
            return null;
        return intro.course.creator.toString() === user._id.toString() ? intro : null;
    }

    static* updateIntro(introId, fileUrl, fileThumbnailUrl, order, fileSharingUrl) {
        const qualities = parseIntroQualities(fileUrl, fileThumbnailUrl, order, fileSharingUrl);
        yield IntroModel.update({_id: introId}, {$set: qualities});
        return yield IntroModel.findOne({_id: introId}).exec();
    }

    static* deleteIntro(introId) {
        const intro = yield IntroModel.findOne({_id: introId}).exec();
        return yield intro.remove();
    }

    static* updateOrder(introId, order) {
        yield IntroModel.update({_id: introId}, {$set: {order}});
        return yield IntroModel.findOne({_id: introId}).exec();
    }

    static* findIntroById(introId) {
        return yield IntroModel.findOne({_id: introId}).exec();
    }
}

const parseIntroQualities = (fileUrl, fileThumbnailUrl, order, fileSharingUrl) => {
    const qualities = {};
    if (fileUrl)
        qualities.fileUrl = fileUrl;
    if (fileThumbnailUrl)
        qualities.fileThumbnailUrl = fileThumbnailUrl;
    if (order)
        qualities.order = Number(order);
    if (fileSharingUrl)
        qualities.fileSharingUrl = fileSharingUrl;
    return qualities;
};

module.exports = IntroRepository;
