import React, {Component} from 'react';
import {Item, Grid} from 'semantic-ui-react';
import dateFormat from '../../helpers/dateFormat';
import TimeStatus from './TimeStatus';

class SessionItem extends Component {
  render() {
    const {session} = this.props;
    return (
      <Grid.Row columns={2} key={session.id}>
        <Grid.Column mobile={16} tablet={10} computer={12}>
          <Item.Group className={'ml10 mr10'}>
            <Item as='div'>
              <Item.Content>
                <Item.Header>
                  <span className="mr10">{ session.title }</span>
                </Item.Header>
                <Item.Meta>
                  <TimeStatus status={ session.timeStatus }/>
                </Item.Meta>
                <Item.Description>
                  { session.description }
                </Item.Description>
                <Item.Extra>
                  {dateFormat(session.startAt)}<span> — </span>{dateFormat(session.startAt + 60 * session.duration) }
                </Item.Extra>
              </Item.Content>
            </Item>
          </Item.Group>
        </Grid.Column>
        <Grid.Column mobile={16} tablet={6} computer={4} textAlign="center">
        </Grid.Column>
      </Grid.Row>
    );
  }
}

export default SessionItem;
