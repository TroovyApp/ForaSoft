import React, {Component} from 'react';
import Screen from '../layouts/Screen';
import { Icon } from 'semantic-ui-react';

const styles = require('./Page404.sass');

class Page404 extends Component {
  render() {
    return (
      <Screen
        showHeader={false}
        fullScreen={true}
        content={
          <div className={styles.Content}>
            <h1>
              <Icon name='linkify' size={'big'}/>
              Page not found. Go to
              <a href="/admin/dashboard/users"> index page</a>
            </h1>
          </div>
        }
      />
    );
  }
}

Page404.defaultProps = {};

export default Page404;
