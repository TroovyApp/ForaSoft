import React, {Component} from 'react';
import ActionModal from '../../components/common/Modal/ActionModal';
import UserCard from '../../components/common/User/UserCard';
import RaisedButton from 'material-ui/RaisedButton';
import {Header} from 'semantic-ui-react';

import {
  TableRow,
  TableRowColumn
} from 'material-ui/Table';

const styles = require('./Users.sass');


class UsersItem extends Component {
  render() {
    const {user} = this.props;
    const {onDisableUser, onCancelDisableUser} = this.props;
    return ( <TableRow>
        <TableRowColumn style={{width: 'auto'}}>
          <UserCard image={user.imageUrl}
                    name={user.name}
                    className={styles.UserProfile}/>
        </TableRowColumn>
        <TableRowColumn className={"text-center"} style={{width: '120px'}}>
          { user.phoneNumber ? `${user.dialCode}${user.phoneNumber}` : 'not connected' }
        </TableRowColumn>
        <TableRowColumn style={{width: '250px'}}>
          <div style={{width: '160px', margin: '0 auto'}}>
            <ActionModal
              trigger={<RaisedButton
                label={user.isDisabled ? 'Enable' : 'Disable'}
                primary={user.isDisabled}
                style={{fontSize: '13px !important'}}
              />}
              requestStatus={user.requestStatus}
              lastError={ user.lastError }
              header={<Header icon={user.isDisabled ? "unlock" : "lock"}
                              content={`Are you sure you want to ${user.isDisabled ? "enable" : "disable"} this user?`}/>}
              statusContent={{
                loadingContent: `${user.isDisabled ? "Enabling" : "Disabling"} user in progress ...`
              }}
              onAccept={onDisableUser}
              onCancel={onCancelDisableUser}
            />
            <div className={user.isDisabled ? styles.disabledLabel : styles.enabledLabel}>Disabled</div>
          </div>
        </TableRowColumn>
      </TableRow>
    );
  }
}

export default UsersItem;
