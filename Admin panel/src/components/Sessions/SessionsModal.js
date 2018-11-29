import React, {Component} from 'react';
import SessionsList from '../../components/Sessions/SessionsList';
import {Icon, Modal} from 'semantic-ui-react';
import FlatButton from 'material-ui/FlatButton';
import RaisedButton from 'material-ui/RaisedButton';

class SessionsModal extends Component {
  state = {modalOpen: false};

  handleOpen = () => this.setState({modalOpen: true});

  handleClose = () => this.setState({modalOpen: false});

  render() {
    const {sessions, courseName} = this.props;
    return <Modal trigger={<RaisedButton label="Show sessions list" primary={true}
                                         fullWidth={true}
                                         className={'invisible'}/>}
                  open={this.state.modalOpen}
                  onClose={this.handleClose}
                  onOpen={this.handleOpen}
    >
      <Modal.Header>Sessions in a Course "{courseName}"</Modal.Header>
      <Modal.Content scrolling>
        <Modal.Description>
          <SessionsList sessions={sessions}/>
        </Modal.Description>
      </Modal.Content>
      <Modal.Actions>
        <div>
          <FlatButton primary={true} onClick={this.handleClose}>
            <Icon name='checkmark'/> <span>Close</span>
          </FlatButton>
        </div>
      </Modal.Actions>
    </Modal>;
  }
}

export default SessionsModal;
