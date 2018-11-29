import React, {Component} from 'react';
import { Label } from 'semantic-ui-react'


class TimeStatus extends Component {
  render(){
    switch(this.props.status ){
      case 0:
        return <Label color={'blue'}>Upcoming</Label>;
      case 1:
        return <Label color={'green'}>In Progress</Label>;
      case 2:
        return <Label color={'brown'}>Past</Label>;
      default:
        return <Label color={'grey'}>None</Label>;
    }
  }
}

export default TimeStatus;
