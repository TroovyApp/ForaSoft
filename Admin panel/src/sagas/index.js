import {put, call, takeLatest} from 'redux-saga/effects'
import * as Api from '../services/troovyApi';
import * as ACTION_TYPES from '../constants/actionsTypes';
import moneyFormat from '../helpers/moneyFormat';
import pause from '../helpers/saga/pause';
import REQUEST_STATUSES from '../constants/requestStatuses';
import mapToAssocWithRequestInfo from '../helpers/saga/toAssoc';

function* fetchLoginAdmin(action) {
  try {
    const {email} = action;
    const response = yield call(Api.loginAdmin, email, action.fields.password);
    yield call(pause);
    yield put({type: ACTION_TYPES.LOGIN_FETCH_SUCCEEDED, user: response});
  } catch (e) {
    yield put({type: ACTION_TYPES.LOGIN_FETCH_FAILED, message: e.message});
  }
}

function* fetchLogoutAdmin(action) {
  try {
    const response = yield call(Api.logoutAdmin, {});
    yield put({type: ACTION_TYPES.LOGOUT_FETCH_SUCCEEDED, user: response});
  } catch (e) {
    yield put({type: ACTION_TYPES.LOGOUT_FETCH_FAILED, message: e.message});
  }
}

function* fetchUsersList(action) {
  try {
    const {count, page, orderMod} = action.fields;
    let response = yield call(Api.getUsersList, count, page, orderMod);
    response.items = mapToAssocWithRequestInfo(response.items);
    yield put({type: ACTION_TYPES.USERS_LIST_FETCH_SUCCEEDED, usersList: response, count, page});
  } catch (e) {
    yield put({type: ACTION_TYPES.USERS_LIST_FETCH_FAILED, message: e.message});
  }
}

function* fetchDisableUser(action) {
  const {userId, currentStatus} = action.fields;
  try {
    const response = yield call(Api.disableUser, userId, currentStatus);
    yield put({type: ACTION_TYPES.DISABLE_USER_FETCH_SUCCEEDED, userUpdated: response});
  } catch (e) {
    yield put({type: ACTION_TYPES.DISABLE_USER_FETCH_FAILED, message: e.message, userDisableId: userId});
  }
}

function* fetchCoursesList(action) {
  try {
    const {count, orderMod} = action.fields;
    let {page} = action.fields;
    let response = yield call(Api.getCoursesList, count, page, orderMod);

    // search not empty page if this page is empty
    while (response.items.length === 0 && page > 1) {
      page--;
      response = yield call(Api.getCoursesList, count, page, orderMod);
    }

    response.items = mapToAssocWithRequestInfo(response.items);
    yield put({type: ACTION_TYPES.COURSES_LIST_FETCH_SUCCEEDED, response, count, page});
  } catch (e) {
    yield put({type: ACTION_TYPES.COURSES_LIST_FETCH_FAILED, message: e.message});
  }
}

function* fetchRemoveCourse(action) {
  const {courseId, ignoreSubscribers, ignoreActiveSession} = action.fields;
  try {
    yield call(Api.removeCourse, courseId, ignoreSubscribers, ignoreActiveSession);
    yield put({type: ACTION_TYPES.REMOVE_COURSE_FETCH_SUCCEEDED, courseRemovedId: courseId});
  } catch (e) {
    if (e.code === 0)
      yield put({type: ACTION_TYPES.REMOVE_COURSE_FETCH_FAILED, message: e.message, courseRemoveId: courseId});
    else
      yield put({
        type: ACTION_TYPES.REMOVE_COURSE_FETCH_SUCCEEDED_WITH_ERROR,
        message: e.message,
        courseRemoveId: courseId
      });
  }
}

function* fetchWithdrawalsList(action) {
  try {
    const {count, page} = action.fields;
    const response = yield call(Api.getWithdrawalList, count, page);
    response.items = mapToAssocWithRequestInfo(response.items);
    yield put({type: ACTION_TYPES.WITHDRAWAL_LIST_FETCH_SUCCEEDED, withdrawalsList: response, count, page});
  } catch (e) {
    yield put({type: ACTION_TYPES.WITHDRAWAL_LIST_FETCH_FAILED, message: e.message});
  }
}

function* fetchApproveWithdrawal(action) {
  const {withdrawalId} = action.fields;
  try {
    const response = yield call(Api.approveWithdrawal, withdrawalId);
    yield put({type: ACTION_TYPES.APPROVE_WITHDRAWAL_FETCH_SUCCEEDED, withdrawalUpdated: response});
  } catch (e) {
    if (e.message && e.message.credits) {
      const credits = moneyFormat(e.message.credits);
      e.message = `The user's balance less than amount of withdrawal. Current user balance: ${credits}`;
    }

    yield put({type: ACTION_TYPES.APPROVE_WITHDRAWAL_FETCH_FAILED, message: e.message, withdrawalId});
  }
}


function* rootSaga() {
  yield takeLatest(ACTION_TYPES.LOGIN_FETCH_REQUESTED, fetchLoginAdmin);
  yield takeLatest(ACTION_TYPES.USERS_LIST_FETCH_REQUESTED, fetchUsersList);

  yield takeLatest(ACTION_TYPES.DISABLE_USER_FETCH_REQUESTED, fetchDisableUser);
  yield takeLatest(ACTION_TYPES.LOGOUT_FETCH_REQUESTED, fetchLogoutAdmin);

  yield takeLatest(ACTION_TYPES.COURSES_LIST_FETCH_REQUESTED, fetchCoursesList);
  yield takeLatest(ACTION_TYPES.REMOVE_COURSE_FETCH_REQUESTED, fetchRemoveCourse);

  yield takeLatest(ACTION_TYPES.WITHDRAWAL_LIST_FETCH_REQUESTED, fetchWithdrawalsList);
  yield takeLatest(ACTION_TYPES.APPROVE_WITHDRAWAL_FETCH_REQUESTED, fetchApproveWithdrawal);
}

export default rootSaga;