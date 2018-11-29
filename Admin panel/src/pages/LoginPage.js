import React, {Component} from 'react';
import Screen from 'layouts/Screen';
import LoginContainer from 'containers/Auth/LoginContainer';
import {Grid} from 'semantic-ui-react';
import {connect} from 'react-redux'
import {Redirect} from 'react-router';

class LoginPage extends Component {
  render() {
    const {isAuth} = this.props.user;
    if (isAuth) {
      return <Redirect to='/admin/dashboard/users'/>;
    }
    return (
      <Screen
        content={
          <Grid centered>
            <Grid.Column mobile={16} tablet={12} computer={8}>
              <LoginContainer/>
            </Grid.Column>
          </Grid>
        }
      />
    );
  }
}

function mapStateToProps(state) {
  return {
    user: state.user
  }
}

export default connect(mapStateToProps)(LoginPage);
