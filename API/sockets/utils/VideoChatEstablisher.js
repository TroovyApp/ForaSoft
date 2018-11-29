'use strict';

const connectToKurento = require('kurento-client');
const wrap = require('co').wrap;

const KurentoElementResolver = require('./KurentoElementResolver');
const KurentoEndpontFactory = require('./KurentoEndpointFactory');
const createSignalChannel = require('./SignalChannel');
const internalRoute = require('../routes/InternalRoute');

const VideoChatRepository = require('../../repositories/VideoChatRepository');
const SessionParticipantRepository = require('../../repositories/SessionParticipantRepository');

const mediaElementsTypes = require('../../constants/mediaElementsConstants').types;
const logger = require('../../utils/logger');
const apiResponse = require('../../helpers/apiResponse');

const kurentoURL = require('../../config').kurentoURL;
const _wrap = require('../../utils/kurentoWrapper');

class VideoChatEstablisher {
    constructor() {
        this.kurentoPromise = this._getKurentoPromise();
        KurentoElementResolver.setConnectionPromise(this.kurentoPromise);
        this.candidateListeners = {};
        process.on('SIGINT', wrap(this._clearMediaServer.bind(this)));
    }

    _getKurentoPromise() {
        return _wrap(connectToKurento(kurentoURL))
            .then(client => client.get());
    }

    * _clearMediaServer() {
        yield VideoChatRepository.releaseAll();
        setTimeout(() => process.exit(0), 500);
    }

    * publishStream(socket, data, callback) {
        const {sessionId, offerSdp, isVideoEnabled = true} = data;
        const participant = yield SessionParticipantRepository.findBySocketIdAndSessionId(socket.id, sessionId);

        const options = this._getOptions(participant);
        const streamData = {
            sessionId,
            label: participant.user,
            userId: participant.user
        };
        const signalChannelCallback = this._onStreamPublished.bind(this, socket, callback);
        const signalChannelEndpoint = this._makeSignalChannelEndpoint(socket, streamData, signalChannelCallback);

        const wrapper = yield this._makeWebrtcEndpoint(participant.session, offerSdp, options, signalChannelEndpoint);
        const endpoint = wrapper.get();
        yield VideoChatRepository.saveEndpoint(endpoint, participant.session, mediaElementsTypes.PUBLISHER, participant.user, isVideoEnabled);
        yield VideoChatRepository.connectToPublisher(endpoint, participant.session);
    }

    _getOptions(participant, label) {
        return Boolean(label) ? {name: participant.user.toString() + '_' + label} : {name: participant.user.toString()};
    }


    _onStreamPublished(socket, callback, answerSdp) {
        callback && callback(null, {answerSdp});
    }

    /**
     * @api {event} stream:published
     * @apiVersion 1.0.0
     * @apiName StreamPublishedEvent
     * @apiDescription Event when stream was published
     * @apiGroup Streams Socket Events
     *
     * @apiUse StreamInfoResponse
     * */
    onStreamConnected(socket, data, callback) {
        const {sessionId, label, isVideoEnabled} = data;
        internalRoute.emit('internal:emitToRoom', socket, sessionId, 'stream:published', {
            label,
            isVideoEnabled
        });
        callback && callback(apiResponse({}));
    }

    _makeSignalChannelEndpoint(socket, streamData, callback) {
        const signalChannel = createSignalChannel();
        const controllerEndpoint = signalChannel.leftEndpoint;

        controllerEndpoint.once('answer', sdp => callback(sdp));
        controllerEndpoint.on('candidate', candidate => this._emitCandidate(socket, streamData, candidate));

        this._registerIceCandidateListener(streamData, candidate => {
            controllerEndpoint.sendIceCandidate(candidate);
        });

        return signalChannel.rightEndpoint;
    }

    /**
     * @api {event} stream:candidate
     * @apiVersion 1.0.0
     * @apiName StreamCandidateEvent
     * @apiDescription Event with candidate
     * @apiGroup Streams Socket Events
     *
     * @apiUse CandidateResponse
     * */
    _emitCandidate(socket, streamData, candidate) {
        socket.emit('stream:candidate', {candidate, label: streamData.label});
    }

    _registerIceCandidateListener(streamData, listener) {
        const streamLabel = this._makeStreamLabel(streamData);
        const userId = streamData.userId.toString();
        if (!this.candidateListeners[userId]) {
            this.candidateListeners[userId] = {};
        }
        this.candidateListeners[userId][streamLabel] = listener;
    }

    _makeStreamLabel(streamData) {
        const {label, sessionId} = streamData;
        return label + '_' + sessionId;
    }

    * _makeWebrtcEndpoint(liveSession, offerSdp, options, signalChannelEndpoint) {
        const wrapper = yield VideoChatRepository.getOrCreatePipeline(liveSession);
        const pipeline = wrapper.get();
        const endpointFactory = KurentoEndpontFactory.webrtc(pipeline, options);
        return yield endpointFactory.makeFromOffer(offerSdp, signalChannelEndpoint);
    }

    onIceCandidate(data, callback) {
        const streamLabel = this._makeStreamLabel(data);
        const listener = this.candidateListeners[data.userId][streamLabel];
        listener && listener(data.candidate);
        callback && callback(null, apiResponse({}));
    }

    * getStreamInfo(data, callback) {
        const {sessionId} = data;
        const streamInfo = yield VideoChatRepository.getPublishingStreamInfo(sessionId);
        callback && callback(null, streamInfo);
    }

    * playStream(socket, data, callback) {
        const {sessionId, label, offerSdp} = data;
        const participant = yield SessionParticipantRepository.findBySocketIdAndSessionId(socket.id, sessionId);

        const options = this._getOptions(participant, label);
        const streamData = {
            userId: participant.user,
            label,
            sessionId
        };
        const signalChannelCallback = answerSdp => {
            callback(null, {answerSdp})
        };
        const signalChannelEndpoint = this._makeSignalChannelEndpoint(socket, streamData, signalChannelCallback);
        const wrapper = yield this._makeWebrtcEndpoint(participant.session, offerSdp, options, signalChannelEndpoint);
        const endpoint = wrapper.get();
        const mediaElement = yield VideoChatRepository.saveEndpoint(endpoint, participant.session, mediaElementsTypes.VIEWER, participant.user);
        yield this.tryConnectToPublisher(label, endpoint, mediaElement);
    }

    * tryConnectToPublisher(label, endpoint, mediaElement) {
        try {
            const publishMediaElement = yield VideoChatRepository.findByOwnerId(label);
            const publishEndpointWrapper = yield VideoChatRepository.populate(publishMediaElement);
            const publishEndpoint = publishEndpointWrapper.get();
            yield publishEndpoint.connect(endpoint);
            mediaElement.isConnected = true;
            yield mediaElement.save();
        } catch (err) {
            logger.error('Failed connect to publisher');
            logger.error(err.stack);
        }
    }

    /**
     * @api {event} stream:video:enabled
     * @apiVersion 1.0.0
     * @apiName VideoEnabledEvent
     * @apiDescription Event when video is enabled
     * @apiGroup Streams Socket Events
     *
     * @apiUse StreamInfoResponse
     * */
    * enableVideo(socket, data, callback) {
        const {sessionId} = data;
        const publishMediaElement = yield VideoChatRepository.enableVideo(sessionId);
        callback && callback(apiResponse({}));
        this._onChangeVideoState(socket, 'stream:video:enabled', sessionId, publishMediaElement);
    }

    /**
     * @api {event} stream:video:disabled
     * @apiVersion 1.0.0
     * @apiName VideoDisabledEvent
     * @apiDescription Event when video is disabled
     * @apiGroup Streams Socket Events
     *
     * @apiUse StreamInfoResponse
     * */
    * disableVideo(socket, data, callback) {
        const {sessionId} = data;
        const publishMediaElement = yield VideoChatRepository.disableVideo(sessionId);
        callback && callback(apiResponse({}));
        this._onChangeVideoState(socket, 'stream:video:disabled', sessionId, publishMediaElement);
    }

    _onChangeVideoState(socket, message, sessionId, publishMediaElement) {
        internalRoute.emit('internal:emitToRoom', socket, sessionId, message, {
            label: publishMediaElement.owner.toString(),
            isVideoEnabled: publishMediaElement.isVideoEnabled
        });
    }

    * stopStream(participant) {
        try {
            const mediaElements = yield VideoChatRepository.findAllByOwnerId(participant.user);
            const wrappers = yield mediaElements.map(element => {
                return VideoChatRepository.populate(element);
            });
            yield wrappers.map(wrapper => {
                return wrapper.get().release();
            });
            yield mediaElements.map(element => {
                return element.remove();
            });
            yield this._releasePipelineIfSessionEmpty(participant);
        } catch (err) {
            logger.error(`Error during stop stream ${err.stack.toString()}`);
        }
    }

    * _releasePipelineIfSessionEmpty(participant) {
        yield participant.populate({
            path: 'session',
            populate: {
                path: 'mediaElements'
            }
        }).execPopulate();
        const liveSession = participant.session;
        if (!liveSession)
            return;
        const mediaElements = liveSession.mediaElements.filter(element => {
            return element.type !== mediaElementsTypes.PIPELINE;
        });
        if (mediaElements.length === 0) {
            const wrapper = yield VideoChatRepository.getOrCreatePipeline(liveSession);
            yield wrapper.get().release();
            yield liveSession.populate('pipeline').execPopulate();
            if (!liveSession.pipeline)
                return;
            yield liveSession.pipeline.remove();
        }
    }
}

module.exports = VideoChatEstablisher;
