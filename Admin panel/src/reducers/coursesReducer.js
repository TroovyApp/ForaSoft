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

function coursesReducer(state = defaultState, action) {
  const {type} = action;

  switch (type) {
    /* LIST */
    case ACTION_TYPES.COURSES_LIST_FETCH_REQUESTED:
      return Object.assign({}, state, {
        lastError: null,
        requestStatus: REQUEST_STATUSES.REQUESTED
      });
    case ACTION_TYPES.COURSES_LIST_FETCH_SUCCEEDED:
      return {
        currentPage: action.page,
        count: action.count,
        items: action.response.items,
        total: action.response.totalAll,
        lastError: null,
        requestStatus: REQUEST_STATUSES.SUCCEEDED
      };
    case ACTION_TYPES.COURSES_LIST_FETCH_FAILED:
      return Object.assign({}, state, {
        lastError: action.message,
        requestStatus: REQUEST_STATUSES.FAILED
      });
    /* REMOVE */
    case ACTION_TYPES.REMOVE_COURSE_FETCH_SUCCEEDED:
      return Object.assign({}, state, {
        items: removeItem(state.items, action.courseRemovedId),
        total: state.total - 1,
        lastError: null,
      });
    case ACTION_TYPES.REMOVE_COURSE_FETCH_SUCCEEDED_WITH_ERROR:
      return Object.assign({}, state, {
        items: editItem(state.items, action.courseRemoveId, {lastError: action.message.message}, REQUEST_STATUSES.ERROR),
        lastError: null
      });
    case ACTION_TYPES.REMOVE_COURSE_FETCH_REQUESTED:
      return Object.assign({}, state, {
        items: editItem(state.items, action.fields.courseId, {}, REQUEST_STATUSES.REQUESTED),
        lastError: null,
      });
    case ACTION_TYPES.REMOVE_COURSE_FETCH_FAILED:
      return Object.assign({}, state, {
        items: editItem(state.items, action.courseRemoveId, {lastError: action.message}, REQUEST_STATUSES.FAILED),
        lastError: null
      });
    case ACTION_TYPES.REMOVE_COURSE_CANCEL: {
      return Object.assign({}, state, {
        items: editItem(state.items, action.courseRemoveId, {}, REQUEST_STATUSES.NONE),
        lastError: null
      });
    }
    default:
      return state;
  }
}

export default coursesReducer;
