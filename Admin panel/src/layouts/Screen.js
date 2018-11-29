import React, {Component} from 'react';
import classNames from 'classnames';
import {Container, Grid} from 'semantic-ui-react';
import {connect} from 'react-redux';
import logo from '../static/logo_w.png';
import ShadowScrollbars from '../components/common/Scrollbars/ShadowScrollbars';
import Content from './Content';

const styles = require('./Screen.sass');

class Screen extends Component {
  shouldComponentUpdate() {
    return false
  }

  render() {
    const {showHeader, fullScreen} = this.props;
    return <div className={classNames(styles.App)}>
      {
        showHeader ?
          <header className={classNames(styles.AppHeader, this.props.minHeader ? styles.AppHeaderMin : '')}>
            {this.props.header}
          </header> :
          null
      }
      <section
        className={classNames(styles.AppContent, fullScreen ? styles.FullScreen : this.props.minHeader ? styles.AppContentMax : '')}>
        <Content scroll={this.props.minHeader} fullScreen={fullScreen}>
          {this.props.content}
        </Content>
      </section>
      <footer className={classNames(styles.AppFooter)}>
        <Container>
          {this.props.footer}
        </Container>
      </footer>
    </div>
  }
}

Screen.defaultProps = {
  showHeader: true,
  fullScreen: false,
  header: <div>
    <div className={classNames(styles.AppHeaderLogo)}>
      <img src={logo} alt=""/>
    </div>
    <h1 className={classNames(styles.AppTitle)}>Welcome to Troovy admin panel</h1>
  </div>,
  content: <h1>Empty page</h1>,
  footer: <Grid centered>
    <Grid.Column mobile={16} tablet={12} computer={8}>
      <h1>Is empty footer</h1>
    </Grid.Column>
  </Grid>
};

export default Screen;