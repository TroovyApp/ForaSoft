'use strict';

const Command = require('./Command');
const commandTypes = require('./commandTypes');

class RotateAndCropCommand extends Command {
    constructor(sourcePath, outputPath) {
        super();
        this.type = commandTypes.ROTATE_AND_CROP;
        this.sourcePath = sourcePath;
        this.outputPath = outputPath;
    }
}

module.exports = RotateAndCropCommand;