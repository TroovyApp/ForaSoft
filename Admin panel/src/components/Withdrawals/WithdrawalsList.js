import React, {Component} from 'react';
import WithdrawalsItem from './WithdrawalsItem';
import _ from 'lodash';


import {
  Table,
  TableBody,
  TableHeader,
  TableHeaderColumn,
  TableRow,
  TableRowColumn
} from 'material-ui/Table';

const styles = require('./Withdrawals.sass');


class WithdrawalsList extends Component {
  render() {
    const {withdrawals} = this.props;
    return (
      <Table fixedHeader={true} selectable={false} className={styles.tableList}>
        {
          !_.isEmpty(withdrawals) ? <TableHeader displaySelectAll={false}>
            <TableRow>
              <TableHeaderColumn style={{width: 'auto', textAlign: 'left'}}>
                <div className={styles.UserProfileTitle}>
                  Name
                </div>
              </TableHeaderColumn>
              <TableHeaderColumn style={{width: '120px', textAlign: 'center'}}>Phone Number</TableHeaderColumn>
              <TableHeaderColumn style={{width: '250px', textAlign: 'center'}}>Credit card number</TableHeaderColumn>
              <TableHeaderColumn style={{width: '110px', textAlign: 'center'}}>Request</TableHeaderColumn>
              <TableHeaderColumn style={{width: '180px', textAlign: 'center'}}>Actions</TableHeaderColumn>
            </TableRow>
          </TableHeader> : null
        }
        <TableBody displayRowCheckbox={false}>
          {
            !_.isEmpty(withdrawals) ? _.map(withdrawals, (withdrawal) => {
              return <WithdrawalsItem key={withdrawal.id}
                                      withdrawal={withdrawal}
                                      onApproveWithdrawal={this.props.onApproveWithdrawal}
                                      onCancelApproveWithdrawal={this.props.onCancelApproveWithdrawal}
              />;
            }) :
              <TableRow>
                <TableRowColumn>
                  <div className="text-center">
                    There are no requests yet.
                  </div>
                </TableRowColumn>
              </TableRow>
          }
        </TableBody>
      </Table>
    );
  }
}

export default WithdrawalsList;
