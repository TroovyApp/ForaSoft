import React, {Component} from 'react';

import {Icon, Modal} from 'semantic-ui-react';
import FlatButton from 'material-ui/FlatButton';


class InfoModal extends Component {
    state = {modalOpen: false};

    handleOpen = () => {
        return this.setState({modalOpen: true});
    };

    handleClose = () => {
        this.setState({modalOpen: false});
    };

    render() {
        const {trigger, header, content} = this.props;
        return (<Modal
                trigger={trigger}
                open={this.state.modalOpen}
                onClose={this.handleClose}
                onOpen={this.handleOpen}
                size='tiny'
                dimmer={'inverted'}
                closeOnDimmerClick={this.handleClose}
            >
                {header}
                {content}
                <Modal.Actions>
                    <div>
                        <FlatButton primary={true} onClick={this.handleClose}>
                            <Icon name='checkmark'/> <span>Ok</span>
                        </FlatButton>
                    </div>
                </Modal.Actions>
            </Modal>
        )
    }
}

export default InfoModal;
