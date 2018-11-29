import React, {Component} from 'react';
import UsersDashboard from '../../components/Dashboards/UsersDashboard';
import {connect} from 'react-redux';
import {getUsersList, disableUser, cancelDisableUser} from '../../actions';


class UsersDashboardContainer extends Component {
  render() {
    const {users, serverError, requestStatus} = this.props;
    return <UsersDashboard
      users={users.items}
      total={users.total}
      currentPage={users.currentPage}
      serverError={serverError}
      requestStatus={requestStatus}
      onUpdate={(count, page, orderMod) => {
        this.props.dispatch(getUsersList(count, page, orderMod))
      } }
      onDisableUser={(userId, currentStatus) => {
        this.props.dispatch(disableUser(userId, currentStatus))
      } }
      onCancelDisableUser={(userId) => {
        this.props.dispatch(cancelDisableUser(userId))
      } }
    />
  }
}


function mapStateToProps(state) {
  return {
    users: state.users,
    serverError: state.users.lastError,
    requestStatus: state.users.requestStatus
  };
}

export default connect(mapStateToProps)(UsersDashboardContainer);
