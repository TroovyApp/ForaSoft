import * as ACTION_TYPES from  '../constants/actionsTypes';
import REQUEST_STATUSES from '../constants/requestStatuses';
import {editItem, removeItem} from '../helpers/saga/editStoreFunctions';

const defaultState = {
  currentPage: 1,
  count: 20,
  items: [],
  total: 0,
  lastError: null,
  requestStatus: REQUEST_STATUSES.NONE
};

function withdrawalsReducer(state = defaultState, action) {
  const {type} = action;

  switch (type) {
    /* LIST */
    case ACTION_TYPES.WITHDRAWAL_LIST_FETCH_REQUESTED:
      return Object.assign({}, state, {
        lastError: null,
        requestStatus: REQUEST_STATUSES.REQUESTED
      });
    case ACTION_TYPES.WITHDRAWAL_LIST_FETCH_SUCCEEDED:
      return {
        currentPage: action.page,
        count: action.count,
        items: action.withdrawalsList.items,
        total: action.withdrawalsList.totalAll,
        lastError: null,
        requestStatus: REQUEST_STATUSES.SUCCEEDED
      };
    case ACTION_TYPES.WITHDRAWAL_LIST_FETCH_FAILED:
      return Object.assign({}, state, {
        lastError: action.message,
        requestStatus: REQUEST_STATUSES.FAILED
      });
    /* APPROVE */
    case ACTION_TYPES.APPROVE_WITHDRAWAL_FETCH_SUCCEEDED:
      return Object.assign({}, state, {
        items: editItem(state.items, action.withdrawalUpdated.id, action.withdrawalUpdated, REQUEST_STATUSES.SUCCEEDED),
      });
    case ACTION_TYPES.APPROVE_WITHDRAWAL_FETCH_REQUESTED:
      return Object.assign({}, state, {
        items: editItem(state.items, action.fields.withdrawalId, {}, REQUEST_STATUSES.REQUESTED),
      });
    case ACTION_TYPES.APPROVE_WITHDRAWAL_FETCH_FAILED:
      return Object.assign({}, state, {
        items: editItem(state.items, action.withdrawalId, {lastError: action.message}, REQUEST_STATUSES.FAILED),
      });
    case ACTION_TYPES.APPROVE_WITHDRAWAL_FETCH_CANCEL: {
      return Object.assign({}, state, {
        items: editItem(state.items, action.fields.withdrawalId, {}, REQUEST_STATUSES.NONE),
      });
    }
    default:
      return state;
  }
}

export default withdrawalsReducer;
