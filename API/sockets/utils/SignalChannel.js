'use strict';

const EventEmitter = require('events').EventEmitter;

module.exports = function () {
    const leftEndpoint = new SignalChannelEndpoint();
    const rightEndpoint = new SignalChannelEndpoint();

    leftEndpoint.connect(rightEndpoint);
    rightEndpoint.connect(leftEndpoint);

    return {leftEndpoint, rightEndpoint};
};

class SignalChannelEndpoint extends EventEmitter {

    constructor() {
        super();
    }

    connect(destinationEndpoint) {
        this.destinationEndpoint = destinationEndpoint;
    }

    sendAnswer(sdp) {
        this.destinationEndpoint._sendInternalMessage({
            event: 'answer',
            data: sdp
        });
    }

    _sendInternalMessage(message) {
        this.emit(message.event, message.data);
    }

    sendOffer(sdp) {
        this.destinationEndpoint._sendInternalMessage({
            event: 'offer',
            data: sdp
        });
    }

    sendIceCandidate(candidate) {
        this.destinationEndpoint._sendInternalMessage({
            event: 'candidate',
            data: candidate
        });
    }

}
