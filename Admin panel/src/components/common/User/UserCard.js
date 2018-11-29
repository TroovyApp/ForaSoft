import React, {Component} from 'react';
import PropTypes from 'prop-types';
import Avatar from 'material-ui/Avatar';
import ListItem from 'material-ui/List/ListItem';
import {Popup} from 'semantic-ui-react';
import DefaultAvatarImage from '../../../static/default_avatar.png';

class UserCard extends Component {
  render() {
    const {image, name} = this.props;
    return (
      <ListItem
        disabled={true}
        leftAvatar={
          <Avatar
            src={Boolean(image) ? image : DefaultAvatarImage}
            size={30}
            style={{border: '1px solid #6900ff'}}
          />
        }
        primaryText={
          <Popup
            trigger={<div className="longString" style={{fontSize: '13px'}}>{name}</div>}
            content={name}
            position={'bottom left'}
            size={'small'}
            style={{maxWidth: '50%'}}
          />
        }
        {...this.props}
      >
      </ListItem>
    );
  }
}

UserCard.propTypes = {};
UserCard.defaultProps = {
  image: DefaultAvatarImage
};

export default UserCard;
