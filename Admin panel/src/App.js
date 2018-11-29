import React, {Component} from 'react';
import 'semantic-ui-css/semantic.min.css';
import 'theme/global-theme-style.css';
import MuiThemeProvider from 'material-ui/styles/MuiThemeProvider';
import Routes from './routes/AuthRouter';

import troovyTheme from './theme/MuiThemeTroovy';

class App extends Component {
  render() {
    return (
      <MuiThemeProvider muiTheme={troovyTheme}>
        <Routes/>
      </MuiThemeProvider >
    );
  }
}

export default App;
