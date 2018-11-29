import React, {Component} from 'react';
import Screen from './Screen';
import HeadMenu from '../components/Headers/DashboardHeadMenu';
import {authLogout} from '../actions';
import {connect} from 'react-redux'

const styles = require('./Screen.sass');


class ScreenDashboard extends Component {
  render() {
    return (
      <Screen
        minHeader={true}
        header={
          <HeadMenu onLogout={() => {
            this.props.dispatch(authLogout());
          }}/>
        }
        content={
          <div>
            {this.props.children}
          </div>
        }
      />
    );
  }
}


function mapStateToProps(state) {
  return {
    user: state.user,
  }
}

export default connect(mapStateToProps)(ScreenDashboard);

