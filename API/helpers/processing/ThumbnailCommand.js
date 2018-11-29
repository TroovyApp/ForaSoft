'use strict';

const Command = require('./Command');
const commandTypes = require('./commandTypes');

class ThumbnailCommand extends Command {
    constructor(sourcePath, thumbnailDir, thumbnailName) {
        super();
        this.type = commandTypes.THUMBNAIL_COMMAND;
        this.sourcePath = sourcePath;
        this.thumbnailName = thumbnailName;
        this.thumbnailDir = thumbnailDir;
    }
}

module.exports = ThumbnailCommand;
