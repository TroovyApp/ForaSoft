import React, {Component} from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

import Chip from 'material-ui/Chip';
import DefaultAvatarImage from '../../../static/default_avatar.png';
import Avatar from 'material-ui/Avatar';
import {Popup} from 'semantic-ui-react';

const styles = require('./UserChip.sass');


class UserChip extends Component {
  render() {
    const {user} = this.props;
    if (user)
      return (
        <Chip style={{margin: "5px 0"}} className={classNames('longString', styles.CustomChip)}>
          <Avatar src={user.imageUrl ? user.imageUrl : DefaultAvatarImage} style={{minWidth: '32px', minHeight: '32px', border: '1px solid #6900ff'}}/>
          <span style={{width: '100%'}}>
             <span>by</span>
             <Popup
               trigger={<span>{user.name}</span>}
               content={user.name}
               position={'bottom left'}
               size={'small'}
               style={{maxWidth: '50%'}}
             />
             </span>
        </Chip>
      );
    else
      return null;
  }
}

UserChip.propTypes = {};
UserChip.defaultProps = {};

export default UserChip;
