import {camelizeKeys} from 'humps';
import forceLogout from '../helpers/forceLogout';
const request = require('superagent');

const API_PROTOCOL = window.location.protocol ? window.location.protocol : 'http:';

const API_SERVER = Boolean(process.env.REACT_APP_TROOVY_API_SERVER) ? process.env.REACT_APP_TROOVY_API_SERVER : '';
if (!Boolean(API_SERVER)) {
  console.warn(`ERROR: not found REACT_APP_TROOVY_API_SERVER`);
}

const API_PORT = Boolean(process.env.REACT_APP_TROOVY_API_PORT) ? process.env.REACT_APP_TROOVY_API_PORT : '';
if (!API_PORT) {
  console.warn(`ERROR: not found REACT_APP_TROOVY_API_PORT`);
}

const API_HOST = `${API_SERVER}:${API_PORT}`;
const API_PATH = '/api/v1';
const API_ROOT = `${API_PROTOCOL}//${API_HOST}${API_PATH}`;

function callApi(endpoint, method, data = {}) {
  const fullUrl = (endpoint.indexOf(API_ROOT) === -1) ? API_ROOT + endpoint : endpoint;
  let apiRequest = request;
  switch (method) {
    case 'POST' :
      apiRequest = apiRequest
        .post(fullUrl)
        .send(data);
      break;
    case 'PUT' :
      apiRequest = apiRequest
        .put(fullUrl)
        .send(data);
      break;
    case 'DELETE' :
      apiRequest = apiRequest
        .delete(fullUrl)
        .send(data);
      break;
    case 'GET' :
      apiRequest = apiRequest
        .get(fullUrl)
        .query(data);
      break;
    default :
      apiRequest = apiRequest
        .get(fullUrl)
        .query(data);
  }

  return apiRequest
    .set('Content-Type', 'application/json')
    .set('accept', 'json')
    .withCredentials()
    .then(
      response => {
        if (!response.ok)
          throw {message: 'Status error'};
        if (response.body.code === 200) {
          return camelizeKeys(response.body.result);
        }
        else {
          if (response.body.code === 403 && response.body.error === 'Access denied') {
            forceLogout();
          }
          throw {code: response.body.code, message: response.body.error};
        }
      },
      error => {
        // throw {code: 0, message: error.message || 'Something bad happened'};
        throw {code: 0, message: 'Connection error'}
      }
    );
}

/* AUTH */
export const loginAdmin = (email, password) => callApi('/admin/login', 'POST', {email, password});
export const logoutAdmin = () => callApi('/admin/logout', 'POST', {});

/* USERS */
export const getUsersList = (count, page, orderMod) => callApi('/admin/users/list', 'GET', {count, page, orderMod});
export const disableUser = (userId, currentStatus) => callApi(`/admin/user/${userId}/disable`, 'PUT', {isEnable: currentStatus});

/* COURSES */
export const getCoursesList = (count, page, orderMod) => callApi('/admin/courses/list', 'GET', {count, page, orderMod});
export const removeCourse = (courseId, ignoreSubscribers, ignoreActiveSession) => callApi(`/admin/courses/${courseId}`, 'DELETE', {
  ignoreSubscribers,
  ignoreActiveSession
});

/* WITHDRAWAL */
export const getWithdrawalList = (count, page) => callApi('/admin/withdrawals/list', 'GET', {count, page});
export const approveWithdrawal = (withdrawalId) => callApi(`/admin/withdrawals/${withdrawalId}/approve`, 'PUT', {});
