import React, {Component} from 'react';
import {Message, Icon} from 'semantic-ui-react';
import classNames from 'classnames';
const styles = require('./Status.sass');


class StatusError extends Component {
  render() {
    const {content, header, className} = this.props;
    return (
      <div className={classNames(styles.status, className)}>
        <Message icon color='red'>
          <Message.Content>
            <Message.Header>{header}</Message.Header>
            {
              Array.isArray(content) ?
                <ul>
                  {content.map(err => {
                    return <li>{err}</li>;
                  })}
                </ul>
                :
                content
            }
          </Message.Content>
        </Message>
      </div>
    );
  }
}

export default StatusError;
