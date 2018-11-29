import React, {Component} from 'react';
import Paper from 'material-ui/Paper';
import {Divider} from 'semantic-ui-react';

import Pagination from '../../components/common/Pagination/Pagination';
import Notification from '../../components/common/Notification/Notification';
import WithdrawalsList from '../../components/Withdrawals/WithdrawalsList';
import StatusSwitcher from '../../components/common/Statuses/StatusSwitcher';

const styles = require('./Dashborads.sass');


class WithdrawalsDashboard extends Component {
  constructor(props) {
    super(props);
    this.state = {
      count: 10,
      orderMod: 0
    };
  }

  render() {
    const {requestStatus, serverError, total, withdrawals, currentPage} = this.props;
    const errors = serverError ? [serverError] : [];
    const {count, orderMod} = this.state;
    const pages = Math.ceil(total / count);
    return (
      <div>
        <Notification errors={errors}/>
        <Paper zDepth={1} className={ pages > 1 ? styles.WithdrawalsContent : ''}>
          {
            <StatusSwitcher
              status={requestStatus}
              errorContent={errors}
              loadingContent={'Loading withdrawals requests...'}
              success={
                <WithdrawalsList withdrawals={withdrawals}
                                 onApproveWithdrawal={this.props.onApproveWithdrawal}
                                 onCancelApproveWithdrawal={this.props.onCancelApproveWithdrawal}
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

export default WithdrawalsDashboard;
