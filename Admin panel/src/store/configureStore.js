import {createStore, applyMiddleware} from 'redux';
import createLogger from 'redux-logger';
import createSagaMiddleware, {END} from 'redux-saga';
import rootReducer from '../reducers';

const sagaMiddleware = createSagaMiddleware();
const middleware = [sagaMiddleware, createLogger];


export default function configureStore(initialState) {

  const store = createStore(
    rootReducer,
    initialState,
    applyMiddleware(
      ...middleware
    )
  );

  store.runSaga = sagaMiddleware.run;
  store.close = () => store.dispatch(END);
  return store;
}
