import React, {Component} from 'react';
import UsersItem from './UsersItem';
import _ from 'lodash';

import {
  Table,
  TableBody,
  TableHeader,
  TableHeaderColumn,
  TableRow,
  TableRowColumn
} from 'material-ui/Table';

const styles = require('./Users.sass');


class UsersList extends Component {
  render() {
    const {users} = this.props;
    return (
      <Table fixedHeader={true} selectable={false} className={styles.tableUsersList}>
        {
          !_.isEmpty(users) ?  <TableHeader displaySelectAll={false}>
            <TableRow>
              <TableHeaderColumn style={{width: 'auto', textAlign: 'left'}}>
                <div className={styles.UserProfileTitle}>
                  Name
                </div>
              </TableHeaderColumn>
              <TableHeaderColumn style={{width: '120px', textAlign: 'center'}}>Phone Number</TableHeaderColumn>
              <TableHeaderColumn style={{width: '250px', textAlign: 'center'}}>Actions</TableHeaderColumn>
            </TableRow>
          </TableHeader> : null
        }
        <TableBody displayRowCheckbox={false}>
          {
            !_.isEmpty(users) ? _.map(users, (user) => {
              return <UsersItem key={user.id}
                                user={user}
                                onDisableUser={() => {
                                  this.props.onDisableUser(user.id, user.isDisabled)
                                }}
                                onCancelDisableUser={() => {
                                  this.props.onCancelDisableUser(user.id)
                                }}
              />
            }) :
              <TableRow>
                <TableRowColumn>
                  <div className="text-center">
                    There are no users yet.
                  </div>
                </TableRowColumn>
              </TableRow>
          }
        </TableBody>
      </Table>
    );
  }
}

export default UsersList;
