import * as ACTION_TYPES from '../constants/actionsTypes';

export default function action(type, fields = []) {
  return {type, ...fields};
}

export const authLogin = (email, fields = []) => action(ACTION_TYPES.LOGIN_FETCH_REQUESTED, {email, fields});
export const authLogout = () => action(ACTION_TYPES.LOGOUT_FETCH_REQUESTED, {});

export const getUsersList = (count, page, orderMod) => action(ACTION_TYPES.USERS_LIST_FETCH_REQUESTED, {
  fields: {
    count,
    page,
    orderMod
  }
});

export const disableUser = (userId, currentStatus) => action(ACTION_TYPES.DISABLE_USER_FETCH_REQUESTED, {
  fields: {
    userId,
    currentStatus
  }
});

export const cancelDisableUser = (userId) => action(ACTION_TYPES.DISABLE_USER_FETCH_CANCEL, {
  fields: {
    userId
  }
});

export const getCoursesList = (count, page, orderMod) => action(ACTION_TYPES.COURSES_LIST_FETCH_REQUESTED, {
  fields: {
    count,
    page,
    orderMod
  }
});

export const removeCourse = (courseId, ignoreSubscribers, ignoreActiveSession) => action(ACTION_TYPES.REMOVE_COURSE_FETCH_REQUESTED, {
  fields: {courseId, ignoreSubscribers, ignoreActiveSession}
});

export const cancelRemoveCourse = (courseId) => action(ACTION_TYPES.REMOVE_COURSE_CANCEL, {
  courseRemoveId: courseId
});

export const getWithdrawalList = (count, page) => action(ACTION_TYPES.WITHDRAWAL_LIST_FETCH_REQUESTED, {
  fields: {
    count,
    page
  }
});

export const approveWithdrawal = (withdrawalId) => action(ACTION_TYPES.APPROVE_WITHDRAWAL_FETCH_REQUESTED, {
  fields: {
    withdrawalId
  }
});

export const cancelApproveWithdrawal = (withdrawalId) => action(ACTION_TYPES.APPROVE_WITHDRAWAL_FETCH_CANCEL, {
  fields: {
    withdrawalId
  }
});


