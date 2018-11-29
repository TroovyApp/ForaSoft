const socket = io();
let _sessionId;
let _userId;
let _label;
let _video = null;

const ICE_SERVERS = [{
    urls: ['stun:stun.xten.com', 'stun:stun4.l.google.com:19302']
}];

const _candidateListeners = {};

socket.on('session:forceLogout', (data) => {
    console.log('session:forceLogout');
    console.log(data);
    socket.disconnect();
});

socket.on('session:userList', (res) => {
    console.log('session:userList', res);
});

socket.on('session:started', (res) => {
    console.log('session:started', res);
});

socket.on('session:finished', (res) => {
    console.log('session:finished', res);
});

socket.on('stream:candidate', data => {
    const listener = _candidateListeners[data.label];
    listener && listener(data.candidate);
});

socket.on('stream:video:enabled', data => {
    console.log('stream:video:enabled', data);
});

socket.on('stream:video:disabled', data => {
    console.log('stream:video:disabled', data);
});

socket.on('message:received', data => {
    console.log('message:received', data);
});

function sessionJoin(accessToken, sessionId, userId) {
    socket.emit('session:join', {accessToken, sessionId}, (err, res) => {
        console.log(err, res);
        _sessionId = sessionId;
        if (userId)
            _userId = userId;
    });
}

function sessionLeave(sessionId) {
    socket.emit('session:leave', {sessionId}, (err, res) => {
        console.log(err, res);
    });
}

function streamPublish() {
    _requestInputDevice()
        .then(stream => {
            _establishWebrtcConnection(stream, _userId, true);
        });
}


function _requestInputDevice() {
    return new Promise((resolve, reject) => {
        navigator.getUserMedia({video: true, audio: true}, resolve, reject);
    });
}

function _establishWebrtcConnection(stream, label, isPublish) {
    console.log('start webrtc');
    const peerConnection = new window.RTCPeerConnection({
        iceServers: ICE_SERVERS
    });
    if (isPublish)
        peerConnection.addStream(stream);
    const offerPromise = peerConnection.createOffer(_formatOfferOptions(isPublish))
        .then(function publishOffer(offer) {
            peerConnection.setLocalDescription(offer);
            const data = {
                offerSdp: offer.sdp,
                sessionId: _sessionId,
                label
            };
            return new Promise((resolve) => {
                const message = isPublish ? 'stream:publish' : 'stream:play';
                console.log(message);
                socket.emit(message, data, (err, data) => {
                    if (err) return console.log(err);
                    resolve(data.answerSdp);
                });
            });
        });

    const answerPromise = offerPromise
        .then(sdp => _processAnswer(peerConnection, sdp));
    _ensureIceCandidateExchange(label, peerConnection, offerPromise, answerPromise);
    return isPublish ? answerPromise : answerPromise.then(_onRemoteStream.bind(this, peerConnection));
}

function _formatOfferOptions(isPublish) {
    return isPublish ? {
        offerToReceiveAudio: false,
        offerToReceiveVideo: false
    } : {
        offerToReceiveAudio: true,
        offerToReceiveVideo: true
    };
}

function _processAnswer(peerConnection, answerSdp) {
    return Promise.resolve()
        .then(() => {
            const answer = new window.RTCSessionDescription({
                type: 'answer',
                sdp: answerSdp
            });
            peerConnection.setRemoteDescription(answer);
        });
}

function _ensureIceCandidateExchange(label, peerConnection, offerPromise, answerPromise) {
    console.log('add event listeners');
    peerConnection.onicecandidate = function onIceCandidate(event) {
        if (!event.candidate) {
            return;
        }

        offerPromise.then(() => {
            console.log('emit candidate', event.candidate);
            socket.emit('stream:candidate', {
                label,
                userId: _userId,
                candidate: event.candidate,
                sessionId: _sessionId
            }, () => {
            });
        });
    };

    _candidateListeners[label] = dto => {
        answerPromise.then(() => {
            console.log('remote candidate');
            const candidate = new window.RTCIceCandidate(dto);
            peerConnection.addIceCandidate(candidate);
        });
    };
}

function _streamInfo() {
    return new Promise((resolve, reject) => {
        socket.emit('stream:info', {sessionId: _sessionId}, (err, info) => {
            resolve(info);
        });
    });
}

function streamPlay() {
    _streamInfo().then(info => {
        console.log(info);
        _label = info.label;
        _establishWebrtcConnection(null, info.label);
    });
}

function _onRemoteStream(peerConnection) {
    peerConnection.oniceconnectionstatechange = function onIce() {
        if (peerConnection.iceConnectionState === 'completed') {
            delete _candidateListeners[_label];
        }
    };
    peerConnection.onaddstream = function onAddStream(event) {
        console.log('onAddStream', event);
        _video = document.createElement('video');
        _video.width = 640;
        _video.height = 480;
        _video.srcObject = event.stream;
        document.body.appendChild(_video);
        _video.play();
    };
}

function streamStop() {
    return new Promise((resolve, reject) => {
        socket.emit('stream:stop', {sessionId: _sessionId}, (err, result) => {
            if (err)
                return console.log(err);
            if (_video)
                document.body.removeChild(_video);
            resolve();
        });
    })
}

function streamReload() {
    streamStop().then(streamPlay.bind(this));
}

function enableVideo() {
    socket.emit('stream:video:enable', {sessionId: _sessionId}, (err, result) => {
        console.log(err, result);
    });
}

function disableVideo() {
    socket.emit('stream:video:disable', {sessionId: _sessionId}, (err, result) => {
        console.log(err, result);
    });
}

function sendMessage(text) {
    socket.emit('message:send', {text, sessionId: _sessionId}, (err, result) => {
        console.log(err, result);
    });
}