import React from 'react';
import {cyan500} from 'material-ui/styles/colors';
import getMuiTheme from 'material-ui/styles/getMuiTheme';

const muiThemeTroovy = getMuiTheme({
  palette: {
    primary1Color: '#6900ff',
    // primary2Color: cyan700,
    // primary3Color: grey400,
    accent1Color: '#e80ca1',
    // accent2Color: grey100,
    // accent3Color: grey500,
    // textColor: darkBlack,
    // alternateTextColor: white,
    // canvasColor: white,
    // borderColor: grey300,
    // disabledColor: fade(darkBlack, 0.3),
    // pickerHeaderColor: cyan500,
    // clockCircleColor: fade(darkBlack, 0.07),
    // shadowColor: fullBlack,
  }
});

export default muiThemeTroovy;