import React, {Component} from 'react';
import PropTypes from 'prop-types';

import {Header, Icon, Modal} from 'semantic-ui-react';
import FlatButton from 'material-ui/FlatButton';
import REQUEST_STATUSES from '../../../constants/requestStatuses';
import StatusSwitcher from '../../../components/common/Statuses/StatusSwitcher';
import RaisedButton from 'material-ui/RaisedButton';


class ActionModal extends Component {
  state = {modalOpen: false};

  handleOpen = () => {
    return this.setState({modalOpen: true});
  };

  handleClose = () => {
    this.setState({modalOpen: false});
    return this.props.onCancel();
  };

  handleAccept = () => {
    let e = {};
    e.isForce = this.props.requestStatus === REQUEST_STATUSES.ERROR;
    this.props.onAccept(e);
  };

  componentWillReceiveProps(nextProps) {
    switch (nextProps.requestStatus) {
      case REQUEST_STATUSES.SUCCEEDED:
        return this.handleClose();
      default:
        return true;
    }
  }

  render() {
    const {trigger, header, statusContent} = this.props;
    const {requestStatus, lastError} = this.props;
    const stateAction = requestStatus !== REQUEST_STATUSES.REQUESTED;
    return (<Modal
        trigger={trigger}
        open={this.state.modalOpen}
        onClose={this.handleClose}
        onOpen={this.handleOpen}
        size='tiny'
        dimmer={'inverted'}
        closeOnDimmerClick={stateAction}
      >
        {header}
        <StatusSwitcher
          status={requestStatus}
          {...statusContent}
          errorContent={lastError}
        />
        <Modal.Actions>
          <div>
            <FlatButton secondary={true} onClick={this.handleClose}
                        disabled={ !stateAction }>
              <Icon name='remove'/> <span>No</span>
            </FlatButton>
            <FlatButton primary={true} onClick={this.handleAccept}
                        disabled={ !stateAction }>
              <Icon name='checkmark'/> <span>Yes</span>
            </FlatButton>
          </div>
        </Modal.Actions>
      </Modal>
    )
  }
}

ActionModal.propTypes = {};
ActionModal.defaultProps = {
  trigger: <RaisedButton label={'Open modal'}
                         primary={true}
  />,
  requestStatus: REQUEST_STATUSES.NONE,
  lastError: null,
  header: <Header icon='remove circle outline'
                  content={`Are you sure want to ........?`}/>,
  statusContent: {},
  onAccept: () => {
  },
  onCancel: () => {
  }
};

export default ActionModal;
