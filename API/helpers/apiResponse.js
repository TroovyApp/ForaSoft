'use strict';

/**
 * @apiDefine EmptySuccessResponse
 *
 * @apiSuccessExample {json} Success response:
 * HTTP/1.1 200 OK
 * {
 *      "code": 200,
 *      "result": {}
 * }
 *
 * */
module.exports = (result) => {
    return {
        code: 200,
        result
    }
};
