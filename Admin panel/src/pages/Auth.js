import React, {Component} from 'react';
import {connect} from 'react-redux'
import { Redirect } from 'react-router';

class Auth extends Component {
  render() {
    const {isAuth} = this.props.user;
    if (!isAuth) {
      return <Redirect to='/admin/login'/>;
    }
    return <div></div>;
  }
}

function mapStateToProps(state) {
  return {
    user: state.user
  }
}

export default connect(mapStateToProps)(Auth);
