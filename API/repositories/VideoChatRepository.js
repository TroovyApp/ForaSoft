'use strict';

const instanceName = require('../config').instanceName;

const KurentoElementResolver = require('../sockets/utils/KurentoElementResolver');

const MediaElementModel = require('../schemas/MediaElementSchema');
const mediaElementsTypes = require('../constants/mediaElementsConstants').types;

class VideoChatRepository {
    * getOrCreatePipeline(liveSession) {
        return (Boolean(liveSession.pipeline))
            ? yield this._getPipeline(liveSession)
            : yield this._createPipeline(liveSession)
    }

    * _createPipeline(liveSession) {
        const wrapper = yield KurentoElementResolver.create('MediaPipeline');
        const element = wrapper.get();
        element.setName(this._getPipelineName(liveSession._id.toString()));
        const qualities = this._parseElementQualities(element, liveSession, mediaElementsTypes.PIPELINE);
        const mediaElement = yield this._createElement(qualities);
        liveSession.mediaElements.addToSet(mediaElement);
        liveSession.pipeline = mediaElement;
        yield liveSession.save();
        return wrapper;
    }

    _getPipelineName(liveSessionId) {
        return instanceName + '_' + liveSessionId;
    }

    * _getPipeline(liveSession) {
        yield liveSession.populate('pipeline').execPopulate();
        return this.populate(liveSession.pipeline);
    }

    * _createElement(qualities) {
        return yield MediaElementModel.create(qualities);
    }


    populate(element) {
        return KurentoElementResolver.load(element.mediaElementId);
    }

    * releaseAll() {
        const mediaElements = yield this._getAllMediaElements();
        const wrappers = yield mediaElements.map(element => {
            return this.populate(element);
        });
        yield wrappers.map(wrapper => {
            return wrapper.get().release();
        });
        yield this._removeAllMediaElements();
    }

    * _getAllMediaElements() {
        return yield MediaElementModel.find({}).exec();
    }

    * _removeAllMediaElements() {
        const elements = yield MediaElementModel.find({}).exec();
        return yield elements.map(element => {
            return element.remove();
        });
    }

    * saveEndpoint(endpoint, liveSession, type, owner, isVideoEnabled) {
        const qualities = this._parseElementQualities(endpoint, liveSession, type, owner, isVideoEnabled);
        const mediaElement = yield this._createElement(qualities);
        liveSession.mediaElements.addToSet(mediaElement);
        yield liveSession.save();
        return mediaElement;
    }

    _parseElementQualities(endpoint, liveSession, type, owner, isVideoEnabled) {
        const qualities = {};
        if (endpoint) {
            qualities.mediaElementId = endpoint.id;
        }
        if (liveSession) {
            qualities.liveSession = liveSession;
        }
        if (type) {
            qualities.type = type;
        }
        if (owner) {
            qualities.owner = owner;
        }
        if (Boolean(isVideoEnabled))
            qualities.isVideoEnabled = isVideoEnabled;
        return qualities;
    }

    * getPublishingStreamInfo(sessionId) {
        const publishMediaElement = yield this._getPublishMediaElement(sessionId);
        return Boolean(publishMediaElement) ? {
            label: publishMediaElement.owner,
            isVideoEnabled: publishMediaElement.isVideoEnabled
        } : {};
    }

    * findByOwnerId(owner) {
        return yield MediaElementModel.findOne({owner}).exec();
    }

    * findAllByOwnerId(owner) {
        return yield MediaElementModel.find({owner}).exec();
    }

    * connectToPublisher(publishEndpoint, liveSession) {
        yield liveSession.populate({
            path: 'mediaElements',
            match: {
                isConnected: false,
                type: mediaElementsTypes.VIEWER
            }
        }).execPopulate();
        const wrappers = yield liveSession.mediaElements.map(element => {
            return this.populate(element);
        });
        yield wrappers.map(wrapper => {
            return publishEndpoint.connect(wrapper.get());
        });
        yield liveSession.mediaElements.map(element => {
            element.isConnected = true;
            return element.save();
        });
    }

    * enableVideo(sessionId) {
        const publishMediaElement = yield this._getPublishMediaElement(sessionId);
        publishMediaElement.isVideoEnabled = true;
        return yield publishMediaElement.save();
    }

    * disableVideo(sessionId) {
        const publishMediaElement = yield this._getPublishMediaElement(sessionId);
        publishMediaElement.isVideoEnabled = false;
        return yield publishMediaElement.save();
    }

    * _getPublishMediaElement(sessionId) {
        return yield MediaElementModel.findOne({type: mediaElementsTypes.PUBLISHER}).populate({
            path: 'liveSession',
            match: {session: sessionId}
        }).exec();
    }
}

module.exports = new VideoChatRepository();
