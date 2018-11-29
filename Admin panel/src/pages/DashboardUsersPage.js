import React, {Component} from 'react';
import PropTypes from 'prop-types';
import UsersDashboardContainer from '../containers/Dashboards/UsersDashboardContainer';

const styles = require('./DashboardPage.sass');


class DashboardUsersPage extends Component {
  render() {
    return (
      <div>
        <h1 className={styles.DashboardHeader}>
          Users
        </h1>
        <UsersDashboardContainer/>
      </div>
    );
  }
}


export default DashboardUsersPage;
