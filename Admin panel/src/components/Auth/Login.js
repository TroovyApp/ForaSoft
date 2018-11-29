import React, {Component} from 'react';
import RaisedButton from 'material-ui/RaisedButton';
import Paper from 'material-ui/Paper';
import TextField from 'material-ui/TextField';

import classNames from 'classnames';
import {Redirect} from 'react-router';

import validateLoginFields from 'helpers/validations/validateLoginFields';
import StatusSwitcher from '../../components/common/Statuses/StatusSwitcher';
import REQUEST_STATUSES from '../../constants/requestStatuses';

const styles = require('./Login.sass');


class Login extends Component {
  constructor(props) {
    super(props);
    this.state = {
      email: '',
      password: '',
      showError: false,
      errors: [],
      wasSubmit: true,
      isReady: false
    };
  }

  getClientValidationErrors() {
    return validateLoginFields(this.state);
  }

  handleFieldChanged = fieldKey => ({target: {value}}) => {
    const stateChanges = {};
    stateChanges[fieldKey] = value;
    if (fieldKey === 'email') {
      stateChanges[fieldKey] = stateChanges[fieldKey].replace(/\s/g, '');
    }

    this.setState(stateChanges);
    // fix Form autofill
    if (!this.state.showError && this.state.isReady) {
      setTimeout(() => {
        this.setState({showError: true});
      }, 4000)
    }
  };

  handleSubmit = (event) => {
    event.preventDefault();

    this.setState({
      wasSubmit: true,
      showError: true
    });

    const {email, password} = this.state;
    this.props.onLogin(email.trim().toLowerCase(), {password: password.trim()});
  };

  componentDidMount() {
    setTimeout(() => {
      this.setState({isReady: true});
    }, 100)
  }

  render() {
    const {serverError, requestStatus} = this.props;
    const {email, password, wasSubmit, showError} = this.state;
    const clientErrors = wasSubmit ? this.getClientValidationErrors() : {};
    const validationErrors = {
      ...clientErrors,
      serverError
    };
    return (
      <Paper className={classNames(styles.loginForm, 'mt60')} zDepth={4}>
        <form onSubmit={this.handleSubmit}>
          <h1>
            Log In
          </h1>
          <div className={classNames('fh100')}>
            <TextField
              type="text"
              hintText="Email"
              errorText={ showError && email !== null ? validationErrors.email : ''}
              floatingLabelText="Email"
              floatingLabelFixed={true}
              floatingLabelStyle={{color: '#6900ff'}}
              onChange={this.handleFieldChanged('email')}
              value={Boolean(email) ? email : ''}
              fullWidth={true}
            />
          </div>
          <div className={classNames('fh100')}>
            <TextField
              type="password"
              hintText="Password"
              errorText={ showError && password !== null ? validationErrors.password : ''}
              floatingLabelText="Password"
              floatingLabelStyle={{color: '#6900ff'}}
              floatingLabelFixed={true}
              onChange={this.handleFieldChanged('password')}
              value={Boolean(password) ? password : ''}
              fullWidth={true}
            />
          </div>
          <br/>
          <StatusSwitcher
            initial={
              <RaisedButton type="submit"
                            label="Log In"
                            primary={true}
                            disabled={ showError && ( Object.keys(validationErrors).length > 1 || requestStatus === REQUEST_STATUSES.REQUESTED) }
              />
            }
            permanentInitial={true}
            status={requestStatus}
            errorContent={validationErrors.serverError}
            errorClass={''}
            loadingContent={'Log In...'}
            success={
              <Redirect to='/admin/dashboard/users'/>
            }
          />
        </form>
      </Paper>
    );
  }
}

export default Login;
