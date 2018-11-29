import React, {Component} from 'react';
import {Grid} from 'semantic-ui-react';
import CoursesItem from './CoursesItem';
import _ from 'lodash';

class CoursesList extends Component {
  render() {
    const {courses} = this.props;
    return (
      <Grid verticalAlign='top' className={'pl10 pr10'} style={{marginTop: 0, marginBottom: 0}} >
        {
          !_.isEmpty(courses) ? _.map(courses, (course) => {
            return <CoursesItem key={course.id}
                                course={course}
                                onRemoveCourse={this.props.onRemoveCourse}
                                onCancelRemoveCourse={this.props.onCancelRemoveCourse}
            />;
          }) :
            <Grid.Row>
              <Grid.Column>
                <div className="text-center">
                  There are no courses yet.
                </div>
              </Grid.Column>
            </Grid.Row>
        }
      </Grid>
    );
  }
}

export default CoursesList;
