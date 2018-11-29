import React, {Component} from 'react';
import {connect} from 'react-redux'
import {Redirect} from 'react-router-dom';


class Auth extends Component {
  render() {
    const {isAuth} = this.props.user;
    if (!isAuth) {
      return <Redirect to='/admin/login'/>;
    }
    return this.props.children;
  }
}

function mapStateToProps(state) {
  return {
    user: state.user
  }
}

Auth.defaulProps = {
  children: null,
};

export default connect(mapStateToProps)(Auth);
