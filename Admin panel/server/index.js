const express = require('express');
const path = require('path');
const app = express();
const getServerEnvironment = require('./env');
const publicUrl = '';
const env = getServerEnvironment(publicUrl);
app.use('*/static', express.static(path.join(__dirname, '../build/static')));
app.use('*/favicon.ico', express.static(path.join(__dirname, '../build/favicon.ico')));
app.use('*/manifest.json', express.static(path.join(__dirname, '../build/manifest.json')));


app.get('*', function (req, res) {
  res.sendFile(path.join(__dirname, '../build', 'index.html'));
});

app.listen(env.raw.SERVER_REACT_APP_PORT);