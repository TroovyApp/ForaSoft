'use strict';

const kurento = require('kurento-client');
const _wrap = require('../../utils/kurentoWrapper');

const WEBRTC_ENDPOINT = 'WebRtcEndpoint';


module.exports = {
    webrtc(pipelinePromise, options) {
        const instance = new KurentoEndpointFactory(pipelinePromise, WEBRTC_ENDPOINT);
        instance.name = options.name;
        return instance;
    },
};

class KurentoEndpointFactory {
    constructor(pipeline, kurentoElementName) {
        this.pipeline = pipeline;
        this.kurentoElementName = kurentoElementName;
    }

    makeFromOffer(sdp, signalChannelEndpoint) {
        this.signalChannelEndpoint = signalChannelEndpoint;

        return this.pipeline.create(this.kurentoElementName)
            .then(endpoint => this.endpoint = endpoint)
            .then(() => this._initializeEndpoint())
            .then(() => this.endpoint.processOffer(sdp))
            .then(sdp => signalChannelEndpoint.sendAnswer(sdp))
            .then(() => this._ensureIceCandidateGathering())
            .then(() => {
                return {get: () => this.endpoint};
            });
    }

    _initializeEndpoint() {
        this._ensureIceCandidateExchange();

        return this._setEndpointName().then(() => {
            return this._setBandwidth();
        });
    }

    _ensureIceCandidateExchange() {
        if (!this.trickleIce)
            return;

        this.endpoint.on('OnIceCandidate', event => {
            const candidate = kurento.getComplexType('IceCandidate')(event.candidate);
            this.signalChannelEndpoint.sendIceCandidate(candidate);
        });
        this.signalChannelEndpoint.on('candidate', dto => {
            const candidate = kurento.getComplexType('IceCandidate')(dto);
            this.endpoint.addIceCandidate(candidate);
        });
    }

    _setEndpointName() {
        if (!this.name)
            return;

        return this.endpoint.setName(this.name);
    }

    _setBandwidth() {
        return this.endpoint.setMaxVideoRecvBandwidth(0)
            .then(() => this.endpoint.setMaxOutputBitrate(0))
            .then(() => this.endpoint.setMaxVideoSendBandwidth(0));
    }

    _ensureIceCandidateGathering() {
        if (!this.trickleIce)
            return;

        this.endpoint.gatherCandidates();
    }

    get trickleIce() {
        return this.kurentoElementName === WEBRTC_ENDPOINT;
    }
}
