import React, {Component} from 'react';
import PropTypes from 'prop-types';
import WithdrawalsDashboardContainer from '../containers/Dashboards/WithdrawalsDashboardContainer';

const styles = require('./DashboardPage.sass');


class DashboardWithdrawalsPage extends Component {
  render() {
    return (
      <div>
        <h1 className={styles.DashboardHeader}>
          Withdrawal Requests
        </h1>
        <WithdrawalsDashboardContainer/>
      </div>
    );
  }
}

export default DashboardWithdrawalsPage;

