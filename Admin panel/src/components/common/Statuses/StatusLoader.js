import React, {Component} from 'react';
import { Loader } from 'semantic-ui-react'
import classNames from 'classnames';
const styles = require('./Status.sass');


class StatusLoader extends Component {
  render() {
    const {content, className} = this.props;
    return (
      <div className={classNames(styles.status, 'customLoader', className)}>
        <Loader active inline='centered' size="large" content={content ? content : 'Loading'} />
      </div>
  );
  }
}

StatusLoader.defaultProps = {};

export default StatusLoader;
