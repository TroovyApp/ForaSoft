import React, {Component} from 'react';
import CoursesDashboard from '../../components/Dashboards/CoursesDashboard';
import {connect} from 'react-redux';
import {getCoursesList} from '../../actions';
import {removeCourse, cancelRemoveCourse} from '../../actions';


class CoursesDashboardContainer extends Component {
  render() {
    const {courses, serverError, requestStatus} = this.props;
    return <CoursesDashboard
      courses={courses.items}
      total={courses.total}
      currentPage={courses.currentPage}
      serverError={serverError}
      requestStatus={requestStatus}
      onUpdate={(count, page, orderMod) => {
        this.props.dispatch(getCoursesList(count, page, orderMod))
      } }
      onRemoveCourse={(courseId, isForceRemove) => {
        this.props.dispatch(removeCourse(courseId, isForceRemove, isForceRemove))
      } }
      onCancelRemoveCourse={(courseId) => {
        this.props.dispatch(cancelRemoveCourse(courseId))
      } }
    />
  }
}

function mapStateToProps(state) {
  return {
    courses: state.courses,
    serverError: state.courses.lastError,
    requestStatus: state.courses.requestStatus
  };
}

export default connect(mapStateToProps)(CoursesDashboardContainer);
