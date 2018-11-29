import React, {Component} from 'react';
import {Route, Switch, Redirect} from 'react-router-dom';

import ScreenDashboard from '../layouts/ScreenDashboard';
import DashboardUsersPage from '../pages/DashboardUsersPage';
import DashboardCoursesPage from '../pages/DashboardCoursesPage';
import DashboardWithdrawalsPage from '../pages/DashboardWithdrawalsPage';
import Auth from '../components/Auth/Auth';


class PrivateRoutes extends Component {
  render() {
    return <Auth>
      <ScreenDashboard>
        <Switch>
          <Route exact path="/admin/dashboard/users" component={DashboardUsersPage}/>
          <Route path="/admin/dashboard/courses" component={DashboardCoursesPage}/>
          <Route exact path="/admin/dashboard/withdrawal" component={DashboardWithdrawalsPage}/>
          <Route component={() => {
            return <Redirect to="/admin/dashboard/users"/>
          }
          }/>
        </Switch>
      </ScreenDashboard>
    </Auth>;
  }
}


export default PrivateRoutes;
