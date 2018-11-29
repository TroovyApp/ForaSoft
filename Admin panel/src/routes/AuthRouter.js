import React, {Component} from 'react';
import {Switch, Route, Redirect} from 'react-router';
import PrivateRoutes from './PrivateRoutes';
import PublicRoutes from './PublicRoutes';
import Page404 from '../pages/Page404';


class AuthRouter extends Component {
  render() {
    return (
      <Route path="/admin" component={
        () => {
          return <Switch>
            <Route path='/admin/dashboard' component={PrivateRoutes}/>
            <Route path='/admin' component={PublicRoutes}/>
            <Route path="*" component={Page404}/>
          </Switch>;
        }
      }>
      </Route>
    );
  }
}

AuthRouter.defaultProps = {};


export default AuthRouter;

