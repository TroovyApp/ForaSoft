'use strict';
const ffmpeg = require('fluent-ffmpeg');

const Command = require('./Command');
const commandTypes = require('./commandTypes');
const FFMPEG_BIN = require('../../config').ffmpegBin;

class FfmpegManager {
    constructor() {
        this.queue = [];
        this.currentCommand = null;
    }

    run(command) {
        if (!(command instanceof Command))
            throw new Error('Illegal argument');

        this.queue.push(command);
        this._next();
    }

    _next() {
        if (this.currentCommand)
            return;

        this.currentCommand = this.queue.pop();
        this._execute();
    }

    _execute() {
        if (!this.currentCommand)
            return;

        switch (this.currentCommand.getType()) {
            case commandTypes.THUMBNAIL_COMMAND:
                this._thumbnail();
                break;
            case commandTypes.ROTATE_AND_CROP:
                this._rotateAndCrop();
                break;
            case commandTypes.MINI_THUMBNAIL:
                this._miniThumbnail();
                break;
        }
    }

    _thumbnail() {
        const {thumbnailDir, thumbnailName} = this.currentCommand;
        ffmpeg(this.currentCommand.sourcePath)
            .screenshots({
                timestamps: ['10%'],
                folder: thumbnailDir,
                filename: thumbnailName,
                size: '320x?'
            })
            .on('error', (err) => {
                this.currentCommand.error(err);
                this.currentCommand = null;
                this._next();
            })
            .on('end', () => {
                this.currentCommand.finish();
                this.currentCommand = null;
                this._next();
            });
    }

    _rotateAndCrop() {
        const {sourcePath, outputPath} = this.currentCommand;
        const command = ffmpeg(sourcePath);
        if (FFMPEG_BIN)
            command.setFfmpegPath(FFMPEG_BIN);
        command
            .videoBitrate('2500k')
            .videoFilter('crop=in_h/16*9:in_h')
            .size('720x?')
            .aspectRatio('9:16')
            .output(outputPath)
            .on('error', err => {
                this.currentCommand.error(err);
                this.currentCommand = null;
                this._next();
            })
            .on('end', () => {
                this.currentCommand.finish();
                this.currentCommand = null;
                this._next();
            })
            .run();
    }

    _miniThumbnail() {
        const {sourcePath, outputPath} = this.currentCommand;
        const command = ffmpeg(sourcePath);
        if (FFMPEG_BIN)
            command.setFfmpegPath(FFMPEG_BIN);

        command.size('240x?')
            .output(outputPath)
            .on('error', err => {
                this.currentCommand.error(err);
                this.currentCommand = null;
                this._next();
            })
            .on('end', () => {
                this.currentCommand.finish();
                this.currentCommand = null;
                this._next();
            })
            .run();
    }
}

module.exports = new FfmpegManager();
