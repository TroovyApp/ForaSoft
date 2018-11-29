import * as ACTION_TYPES from  '../constants/actionsTypes';
import Cookies from 'cookies-js';
import REQUEST_STATUSES from '../constants/requestStatuses';
import forceLogout from '../helpers/forceLogout';

const isAuth = Number(Cookies.get('isAuth'));

const defaultState = {
  isAuth: isAuth === 1,
  email: null,
  lastError: null,
  requestStatus: REQUEST_STATUSES.NONE
};

function authReducer(state = defaultState, action) {
  const {type} = action;

  switch (type) {
    /* LOGIN */
    case ACTION_TYPES.LOGIN_FETCH_REQUESTED:
      return Object.assign({}, state, {
        requestStatus: REQUEST_STATUSES.REQUESTED
      });
    case ACTION_TYPES.LOGIN_FETCH_SUCCEEDED:
      return {
        isAuth: 1,
        email: action.email,
        lastError: null,
        requestStatus: REQUEST_STATUSES.SUCCEEDED
      };
    case ACTION_TYPES.LOGIN_FETCH_FAILED:
      return {
        isAuth: 0,
        email: null,
        lastError: action.message,
        requestStatus: REQUEST_STATUSES.FAILED
      };
    /* LOGOUT */
    case ACTION_TYPES.LOGOUT_FETCH_SUCCEEDED:
      return {
        isAuth: 0,
        email: null,
        lastError: null
      };
    case ACTION_TYPES.LOGOUT_FETCH_FAILED:
      forceLogout();
      return {
        isAuth: 0,
        email: null,
        lastError: null
      };
    default:
      return state;
  }
}

export default authReducer;
