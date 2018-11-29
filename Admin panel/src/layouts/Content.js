import React, {Component} from 'react';
import ShadowScrollbars from '../components/common/Scrollbars/ShadowScrollbars';
import {Container} from 'semantic-ui-react';


class Content extends Component {
  render() {
    const {fullScreen, scroll} = this.props;

    const viewContent = fullScreen ?
      this.props.children :
      <Container >
        <div id="contentMain"/>
        {this.props.children}
        <div id="contentMainBottom"/>
      </Container>;

    if (scroll) {
      return <ShadowScrollbars style={{height: `calc(100vh -  67px)`}}>
        {viewContent}
      </ShadowScrollbars>;
    }
    else {
      return viewContent;
    }
  }
}

Content.defaultProps = {
  fullScreen: false,
  scroll: false
};

export default Content;
