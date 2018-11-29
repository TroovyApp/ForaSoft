'use strict';
const mongoose = require('mongoose');
const moment = require('moment');
const Schema = mongoose.Schema;

const MessageSchema = new Schema({
    session: {type: Schema.ObjectId, ref: 'LiveSession'},
    sender: {type: Schema.ObjectId, ref: 'User'},
    text: {type: String},
    timestamp: {type: Date},
    isHighlighted: {type: Boolean, default: false}
}, {collection: 'Message'});

MessageSchema.methods.toDTO = function () {
    return {
        messageId: this._id,
        senderId: this.sender._id,
        senderName: this.sender.name,
        senderImageUrl: this.sender.imageUrl ? this.sender.imageUrl : '',
        text: this.text,
        timestamp: moment(this.timestamp).unix(),
        isHighlighted: this.isHighlighted
    };
};

module.exports = mongoose.model('Message', MessageSchema);
