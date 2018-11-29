'use strict';

const express = require('express');
const cors = require('cors');
const path = require('path');
const favicon = require('serve-favicon');
const logger = require('morgan');
const cookieParser = require('cookie-parser');
const cookieSession = require('cookie-session');
const bodyParser = require('body-parser');
const methodOverride = require('method-override');
const http = require('http');
const fs = require('fs');

const config = require('./config');
const ADMIN_CONSTANTS = require('./constants/adminConstants');

require('./helpers/connectToDB');

const users = require('./controllers/usersController');
const courses = require('./controllers/coursesController');
const sessions = require('./controllers/sessionsController');
const uploader = require('./controllers/uploaderController');
const attachments = require('./controllers/attachmentController');
const reports = require('./controllers/reportController');
const payments = require('./controllers/paymentsController');
const withdrawals = require('./controllers/withdrawalController');
const admin = require('./controllers/adminController');
const messages = require('./controllers/messagesController');
const intro = require('./controllers/introController');

const webPages = require('./web/PagesController');


const app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'hbs');
app.set('env', config.env || 'development');

app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(methodOverride());
app.use(bodyParser.urlencoded({extended: true}));
app.use(cookieSession({
    name: 'session',
    secret: config.cookieSessionSecret ? config.cookieSessionSecret : 'JDxI8U5bkR',
    maxAge: ADMIN_CONSTANTS.SESSION_LIFE_TIME
}));
app.use(cookieParser());

app.use(express.static(path.join(__dirname, 'public')));

const corsOptions = {
    credentials: true,
    origin: config.corsOrigin ? config.corsOrigin : 'http://localhost:3000',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    optionsSuccessStatus: 200 // some legacy browsers (IE11, various SmartTVs) choke on 204
};
app.use(cors(corsOptions));


app.use('/api/v1/users', users);
app.use('/api/v1/courses', courses);
app.use('/api/v1/sessions', sessions);
app.use('/api/v1/upload', uploader);
app.use('/api/v1/attachments', attachments);
app.use('/api/v1/reports', reports);
app.use('/api/v1/payments', payments);
app.use('/api/v1/withdrawals', withdrawals);
app.use('/api/v1/admin', admin);
app.use('/api/v1/messages', messages);
app.use('/api/v1/intro', intro);


app.get('/test', function (req, res) {
    res.render('index', {title: 'Troovy'});
});

app.get('/apple-app-site-association', function (req, res) {
    fs.readFile(__dirname + '/static/apple-app-site-association', (err, file) => {
        res.set('Content-Type', 'application/json');
        if (err)
            return res.status(404).send();
        res.status(200).send(file);
    })
});

app.use('/', webPages);

// catch 404 and forward to error handler
app.use(function (req, res, next) {
    const err = new Error('Not Found');
    err.status = 404;
    next(err);
});

// error handlers

// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
    app.use(function (err, req, res, next) {
        res.status(err.status || 500);
        res.render('error', {
            message: err.message,
            error: err
        });
    });
}

// production error handler
// no stacktraces leaked to user
app.use(function (err, req, res, next) {
    res.status(err.status || 500);
    res.render('error', {
        message: err.message,
        error: {}
    });
});

/**
 * Get port from environment and store in Express.
 */

const port = normalizePort(config.port || process.env.PORT || '3000');
app.set('port', port);

/**
 * Create HTTP server.
 */

const server = http.createServer(app);

/**
 * Listen on provided port, on all network interfaces.
 */

server.listen(port);
server.on('error', onError);
server.on('listening', onListening);
/**
 * Start socket server
 * */
const SocketServer = require('./sockets/SocketServer');
SocketServer.init(server);

/**
 * Normalize a port into a number, string, or false.
 */

function normalizePort(val) {
    const port = parseInt(val, 10);

    if (isNaN(port)) {
        // named pipe
        return val;
    }

    if (port >= 0) {
        // port number
        return port;
    }

    return false;
}

/**
 * Event listener for HTTP server "error" event.
 */

function onError(error) {
    if (error.syscall !== 'listen') {
        throw error;
    }

    const bind = typeof port === 'string'
        ? 'Pipe ' + port
        : 'Port ' + port;

    // handle specific listen errors with friendly messages
    switch (error.code) {
        case 'EACCES':
            console.error(bind + ' requires elevated privileges');
            process.exit(1);
            break;
        case 'EADDRINUSE':
            console.error(bind + ' is already in use');
            process.exit(1);
            break;
        default:
            throw error;
    }
}

/**
 * Event listener for HTTP server "listening" event.
 */

function onListening() {
    const addr = server.address();
    const bind = typeof addr === 'string'
        ? 'pipe ' + addr
        : 'port ' + addr.port;
}

process.on('uncaughtException', function (e) {
    console.log('Uncaught Exception...');
    console.log(e.stack);
});

const FileUtils = require('./helpers/FileUtils');
FileUtils.isExist(FileUtils.getTempDir())
    .then(isExist => {
        if (!isExist)
            FileUtils.makeTempDir();
    });

require('./helpers/runServerStartHook');

module.exports = app;
