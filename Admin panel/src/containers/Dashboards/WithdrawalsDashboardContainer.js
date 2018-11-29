import React, {Component} from 'react';
import WithdrawalsDashboard from '../../components/Dashboards/WithdrawalsDashboard';
import {connect} from 'react-redux';
import {getWithdrawalList, approveWithdrawal, cancelApproveWithdrawal} from '../../actions';


class WithdrawalsDashboardContainer extends Component {
  render() {
    const {withdrawals, serverError, requestStatus} = this.props;
    return <WithdrawalsDashboard
      withdrawals={withdrawals.items}
      total={withdrawals.total}
      currentPage={withdrawals.currentPage}
      serverError={serverError}
      requestStatus={requestStatus}
      onUpdate={(count, page) => {
        this.props.dispatch(getWithdrawalList(count, page))
      } }
      onApproveWithdrawal={(withdrawalId) => {
        this.props.dispatch(approveWithdrawal(withdrawalId))
      } }
      onCancelApproveWithdrawal={(withdrawalId) => {
        this.props.dispatch(cancelApproveWithdrawal(withdrawalId))
      } }
    />
  }
}


function mapStateToProps(state) {
  return {
    withdrawals: state.withdrawals,
    serverError: state.withdrawals.lastError,
    requestStatus: state.withdrawals.requestStatus
  };
}

export default connect(mapStateToProps)(WithdrawalsDashboardContainer);
