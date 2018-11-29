import * as ACTION_TYPES from  '../constants/actionsTypes';
import REQUEST_STATUSES from '../constants/requestStatuses';
import {editItem} from '../helpers/saga/editStoreFunctions';


const defaultState = {
  currentPage: 1,
  count: 20,
  items: [],
  total: 0,
  lastError: null,
  requestStatus: REQUEST_STATUSES.NONE
};

function usersReducer(state = defaultState, action) {
  const {type} = action;

  switch (type) {
    /* LIST */
    case ACTION_TYPES.USERS_LIST_FETCH_REQUESTED:
      return Object.assign({}, state, {
        lastError: null,
        requestStatus: REQUEST_STATUSES.REQUESTED
      });
    case ACTION_TYPES.USERS_LIST_FETCH_SUCCEEDED:
      return {
        currentPage: action.page,
        count: action.count,
        items: action.usersList.items,
        total: action.usersList.totalAll,
        lastError: null,
        requestStatus: REQUEST_STATUSES.SUCCEEDED
      };
    case ACTION_TYPES.USERS_LIST_FETCH_FAILED:
      return Object.assign({}, state, {
        lastError: action.message,
        requestStatus: REQUEST_STATUSES.FAILED
      });
    /* DISABLE */
    case ACTION_TYPES.DISABLE_USER_FETCH_REQUESTED:
      return Object.assign({}, state, {
        items: editItem(state.items, action.fields.userId, {}, REQUEST_STATUSES.REQUESTED),
      });
    case ACTION_TYPES.DISABLE_USER_FETCH_SUCCEEDED:
      return Object.assign({}, state, {
        items: editItem(state.items, action.userUpdated.id, action.userUpdated, REQUEST_STATUSES.SUCCEEDED),
      });
    case ACTION_TYPES.DISABLE_USER_FETCH_FAILED:
      return Object.assign({}, state, {
        items: editItem(state.items, action.userDisableId, {lastError: action.message}, REQUEST_STATUSES.FAILED),
      });
    case ACTION_TYPES.DISABLE_USER_FETCH_CANCEL: {
      return Object.assign({}, state, {
        items: editItem(state.items, action.fields.userId, {}, REQUEST_STATUSES.NONE),
      });
    }
    default:
      return state;
  }
}

export default usersReducer;
