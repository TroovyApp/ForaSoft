const Router = require('router');
const wrap = require('co').wrap;
const path = require('path');
const _isMobile = require('is-mobile');
const formatSession = require('./helpers/formatSession');

const findCourse = require('../domain/coursesUtils').findCourse;
const config = require('../config');
const branch = require('../helpers/BranchRequestHelper');


const router = Router();

router.get('/courses/:courseId', wrap(function* (req, res) {
    try {
        let course = yield findCourse(null, req.params, true);
        course.sessions = course.sessions.map((session) => {
            return formatSession(session);
        });
        const isMobile = _isMobile(req);
        res.render(`web/courses/course-mobile`, Object.assign(course, {
            apiUrl: `${config.host}/api/v1`,
            stripeKey: config.stripePublicKey,
            htmlTitle: course.title.substr(0, 50),
            isMobile
        }));
    } catch (err) {
        res.render('web/404', {
            title: 'Workshop page not found',
            body: 'Workshop page not found'
        });
    }
}));

router.get('/terms-and-conditions', function (req, res) {
    res.render('web/terms');
});

router.get('/privacy', function (req, res) {
    res.render('web/privacy');
});

router.get('/*', wrap(function* (req, res) {
    res.render('web/404', {
        title: 'Page not found',
        body: 'Page not found'
    });
}));

module.exports = router;
