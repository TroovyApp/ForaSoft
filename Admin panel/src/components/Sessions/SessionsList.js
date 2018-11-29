import React, {Component} from 'react';
import {Grid} from 'semantic-ui-react';

import SessionItem from './SessionItem';

class SessionsList extends Component {
  render() {
    const {sessions} = this.props;
    return (
      <Grid verticalAlign='middle'>
        {
          Array.isArray(sessions) && sessions.length > 0 ? sessions.map((session) => {
            return <SessionItem session={session} key={session.id}/>;
          }) :
            <Grid.Row>
              <Grid.Column>
                Empty
              </Grid.Column>
            </Grid.Row>
        }
      </Grid>
    );
  }
}

export default SessionsList;
