import React from 'react';
import ReactDOM from 'react-dom';
import {BrowserRouter as Router} from 'react-router-dom';
import {Provider} from 'react-redux';
import rootSaga from './sagas';
import configureStore from './store/configureStore';

import App from './App';

const store = configureStore();

store.runSaga(rootSaga);


ReactDOM.render(
  <Provider store={store}>
    <Router>
      <App/>
    </Router>
  </Provider>, document.getElementById('root'));
