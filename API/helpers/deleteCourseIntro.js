const deleteIntroVideoHelper = require('../helpers/deleteIntroVideo');
const deleteCourseImageHelper = require('../helpers/deleteCourseImage');


module.exports = function* (course) {
    yield deleteIntroVideoHelper(course);
    yield deleteCourseImageHelper(course);
    return yield course.save();
};
