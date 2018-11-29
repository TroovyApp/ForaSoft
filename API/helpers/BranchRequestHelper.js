const config = require('../config');
const request = require('request-promise');

class BranchRequestHelper {
    static* createLink(courseId, courseTitle, courseDescription, courseLink, courseImage) {
        const branchURL = 'https://api.branch.io/v1/url';
        const response = yield request({
            method: 'POST',
            uri: branchURL,
            body: {
                branch_key: config.branchKey,
                channel: 'Facebook',
                feature: 'sharing',
                canonical_identifier: `courses/${courseId}`,
                data: {
                    courseId,
                    $og_title: courseTitle,
                    $og_description: courseDescription,
                    $og_image_url: courseImage,
                    $og_url: courseLink,
                    $og_image_type: 'image/jpeg',
                    $og_type: 'website'
                }
            },
            json: true
        });
        return response.url;
    }
}

module.exports = BranchRequestHelper;
