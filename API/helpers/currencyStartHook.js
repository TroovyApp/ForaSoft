const CourseSchema = require('../schemas/CourseSchema');
const WithdrawalSchema = require('../schemas/WithdrawalSchema');
const {DEFAULT_CURRENCY} = require('../constants/appConstants');

module.exports = {ensureCurrencyAdded};

function* ensureCurrencyAdded() {
    const courses = yield CourseSchema.find({currency: {$exists: false}}).populate('creator').exec();
    for (let i = 0; i < courses.length; i++) {
        const course = courses[i];
        course.currency = DEFAULT_CURRENCY;
        yield course.save();

        if (!course.creator.currency) {
            course.creator.currency = DEFAULT_CURRENCY;
            yield course.creator.save();
        }
    }

    const withdrawals = yield WithdrawalSchema.find({currency: {$exists: false}}).populate('user').exec();
    for (let i = 0; i < withdrawals.length; i++) {
        const withdrawal = withdrawals[i];
        withdrawal.currency = withdrawal.user.currency;
        yield withdrawal.save();
    }
}
