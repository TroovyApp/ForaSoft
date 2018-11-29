'use strict';

const sessionRoute = require('./routes/SessionRoute');
const streamRoute = require('./routes/StreamRoute');
const messageRoute = require('./routes/MessageRoute');
const internalRoute = require('./routes/InternalRoute');

const SessionController = require('./controllers/SessionController');
const StreamController = require('./controllers/StreamController');
const MessageController = require('./controllers/MessageController');

class SocketServer {
    constructor() {
        this.io = null;
        this._createRoutes();
        this._createControllers();
        this._listenInternalEvents();
    }

    _createRoutes() {
        this.routes = [streamRoute, sessionRoute, messageRoute];
    }

    _createControllers() {
        this.controllers = [new SessionController(), new StreamController(), new MessageController()];
    }

    _listenInternalEvents() {
        internalRoute.on('internal:emitToRoom', this._emitToRoom.bind(this));
        internalRoute.on('internal:emitToAllInRoom', this._emitToAllInRoom.bind(this));
        internalRoute.on('internal:connect', this._connect.bind(this));
        internalRoute.on('internal:disconnect', this._disconnect.bind(this));
        internalRoute.on('internal:emitToUser', this._emitToUser.bind(this));
    }


    init(httpServer) {
        this.io = require('socket.io').listen(httpServer);
        this.io.on('connection', socket => {
            this._listenSocket(socket);
        });
    }

    _listenSocket(socket) {
        this.routes.forEach(route => {
            route.listen(socket);
        });
    }

    _connect(socket, roomId, userId) {
        this._removeSocketFromAllRooms(socket);
        this._addSocketToRoom(socket, roomId);
        this._addSocketToUser(socket, userId);
    }

    _removeSocketFromAllRooms(socket) {
        Object.keys(socket.rooms).filter(roomId => {
            return roomId !== socket.id;
        }).forEach(roomId => {
            socket.leave(roomId);
        });
    }

    _addSocketToRoom(socket, roomId) {
        socket.join(roomId);
    }

    _addSocketToUser(socket, userId) {
        socket.join(userId);
    }

    _disconnect(socket, roomId, userId) {
        if (typeof(socket) === 'string') {
            socket = this.io.sockets.connected[socket];
        }
        if (!socket)
            return;
        this._removeSocketFromRoom(socket, roomId);
        this._removeSocketFromUser(socket, userId);
    }

    _removeSocketFromRoom(socket, roomId) {
        socket.leave(roomId);
    }

    _removeSocketFromUser(socket, userId) {
        socket.leave(userId);
    }

    _emitToRoom(socket, roomId, event, data) {
        socket.broadcast.to(roomId).emit(event, data);
    }

    _emitToUser(userId, event, data) {
        this.io.sockets.in(userId).emit(event, data);
    }

    _emitToAllInRoom(roomId, event, data) {
        this.io.sockets.in(roomId).emit(event, data);
    }
}

module.exports = new SocketServer();
