import authReducer from './authReducer';
import usersReducer from './usersReducer';
import coursesReducer from './coursesReducer';
import withdrawalsReducer from './withdrawalsReducer';

import {combineReducers} from 'redux';

const rootReducer = combineReducers({
  user: authReducer,
  users: usersReducer,
  courses: coursesReducer,
  withdrawals: withdrawalsReducer
});

export default rootReducer;
