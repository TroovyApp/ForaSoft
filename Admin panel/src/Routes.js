import React, {Component} from 'react';
import LoginPage from 'pages/LoginPage';
import DashboardPage from 'pages/DashboardPage';
import Auth from 'pages/Auth';

import {Route} from 'react-router-dom';

class Routes extends Component {
  render() {
    return (
      <div>
        <Route exact path="*" component={Auth}/>
        <Route path="/admin/login"
               component={LoginPage}/>
        <Route path="/admin/dashboard"
               component={DashboardPage}/>
      </div>
    );
  }
}

Routes.propTypes = {};
Routes.defaultProps = {};

export default Routes;
