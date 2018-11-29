import React, {Component} from 'react';
import LoginPage from '../pages/LoginPage';
import {Route, Switch} from 'react-router-dom';


class PublicRoutes extends Component {
  render() {
    return (
      <Switch>
        <Route exact path="/admin/login" component={LoginPage}/>
        <Route path="/admin" component={LoginPage}/>
      </Switch>
    );
  }
}

PublicRoutes.propTypes = {};
PublicRoutes.defaultProps = {};

export default PublicRoutes;
