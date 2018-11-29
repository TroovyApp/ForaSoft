'use strict';

const AttachmentModel = require('../schemas/AttachmentSchema');

class AttachmentRepository {
    static* createAttachment(course, type, params) {
        const attachment = yield AttachmentModel.create({type, params, course: course});
        yield course.attachments.addToSet(attachment);
        yield course.save();
        return attachment;
    }

    static* getCourseAttachments(courseId) {
        const attachments = yield AttachmentModel.find({course: courseId}).exec();
        return attachments.filter(attachment => {
            return Object.keys(attachment.params).length > 0;
        });
    }

    static* getAttachment(user, attachmentId, type) {
        const query = Boolean(type) ? {_id: attachmentId, type} : {_id: attachmentId};
        const attachment = yield AttachmentModel.findOne(query).populate('course').exec();
        if (!attachment)
            return null;
        return attachment.course.creator.toString() === user._id.toString() ? attachment : null;
    }

    static* saveVideoAttach(attachmentId, params) {
        yield AttachmentModel.update({_id: attachmentId}, {$set: {params}});
        return yield AttachmentModel.findOne({_id: attachmentId}).exec();
    }
}

module.exports = AttachmentRepository;
