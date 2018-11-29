import React, {Component} from 'react';
import Paper from 'material-ui/Paper';
import classNames from 'classnames';
import Pagination from '../../components/common/Pagination/Pagination';
import {Divider} from 'semantic-ui-react'
import Notification from 'components/common/Notification/Notification';
import UsersList from '../../components/Users/UsersList';
import StatusSwitcher from '../../components/common/Statuses/StatusSwitcher';

const styles = require('./Dashborads.sass');


class UsersDashboard extends Component {
  constructor(props) {
    super(props);
    this.state = {
      count: 10,
      orderMod: 0
    };
  }

  render() {
    console.log(this.props);
    const {requestStatus, serverError, total, onDisableUser, onCancelDisableUser, currentPage} = this.props;
    const errors = serverError ? [serverError] : [];
    const {count, orderMod} = this.state;
    const pages = Math.ceil(total / count);
    const {users} = this.props;
    return (
      <div className={styles.Container}>
        <Notification errors={errors}/>
        <Paper zDepth={1} className={pages > 1 ? styles.UsersContent : ''}>
          {
            <StatusSwitcher
              status={requestStatus}
              errorContent={errors}
              loadingContent={'Loading users...'}
              // loadingClass={'alignCenter'}
              success={
                <UsersList users={users}
                           onDisableUser={onDisableUser}
                           onCancelDisableUser={onCancelDisableUser}
                />
              }
            />
          }
        </Paper>
        <Pagination pageCount={pages} currentPage={currentPage - 1} onPageChange={(e) => {
          this.props.onUpdate(count, e.selected + 1, orderMod);
        }}/>
        <Divider hidden/>
      </div>
    );
  }
}

export default UsersDashboard;
