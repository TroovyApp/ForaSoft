import React, {Component} from 'react';
import PropTypes from 'prop-types';
import CoursesDashboardContainer from '../containers/Dashboards/CoursesDashboardContainer';

const styles = require('./DashboardPage.sass');


class DashboardCoursesPage extends Component {
  render() {
    return (
      <div>
        <h1 className={styles.DashboardHeader}>
          List of Courses
        </h1>
        <CoursesDashboardContainer/>
      </div>
    );
  }
}

export default DashboardCoursesPage;

