'use strict';

const Command = require('./Command');
const commandTypes = require('./commandTypes');

class MiniThumbnailCommand extends Command {
    constructor(sourcePath, outputPath) {
        super();
        this.type = commandTypes.MINI_THUMBNAIL;
        this.sourcePath = sourcePath;
        this.outputPath = outputPath;
    }
}

module.exports = MiniThumbnailCommand;