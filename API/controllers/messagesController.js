'use strict';

const Router = require('router');
const wrap = require('co').wrap;

const apiResponse = require('../helpers/apiResponse');
const auth = require('../helpers/auth');

const getMessages = require('../domain/messagesUtils').getMessages;

const router = Router();

/**
 * @apiDefine MessageListResponse
 * @apiSuccessExample {json} Message response:
 * {
 *  "code":200,
 *  "result": [
 *         {
 *           "messageId": "59a57aa142d91c369c6d914b",
 *           "senderId": "59a57aa142d91c369c6d914b",
 *           "senderName": "Vladislav",
 *           "text": "Text",
 *           "timestamp": 1504017057,
 *           "isHighlighted": false
 *         }
 *  ]
 * }
 * */

/**
 * @api {get} /api/v1/messages/:sessionId
 * @apiVersion 1.0.0
 * @apiName MessagesList
 * @apiDescription Get messages list
 * @apiGroup Messages
 *
 * @apiParam {String} accessToken Access token
 * @apiParam {String} sessionId Session id provided in URL
 * @apiParam {Number} [count=10] Length of message list
 * @apiParam {Number} [page=1] Page of message list
 *
 * @apiUse ValidationError
 * @apiUse AccessDeniedError
 * @apiUse UserDisabledError
 * */
router.get('/:sessionId', auth, wrap(function* (req, res) {
    try {
        const {sessionId} = req.params;
        const {count = 10, page = 1} = req.query;
        const messages = yield getMessages(sessionId, count, page);
        return res.send(apiResponse(messages.map(message => {
            return message.toDTO();
        })));
    } catch (err) {
        return res.send(err);
    }
}));

module.exports = router;
