import React, {Component} from 'react';
import Paper from 'material-ui/Paper';
import {Divider} from 'semantic-ui-react';

import Pagination from '../../components/common/Pagination/Pagination';
import Notification from '../../components/common/Notification/Notification';

import CoursesList from '../../components/Courses/CoursesList';
import StatusSwitcher from '../../components/common/Statuses/StatusSwitcher';

const styles = require('./Dashborads.sass');


class CoursesDashboard extends Component {
  constructor(props) {
    super(props);
    this.state = {
      count: 10,
      orderMod: 0,
    };
  }

  componentWillReceiveProps(nextProps) {
    const {count, orderMod,} = this.state;
    const {currentPage} = this.props;

    if (
      this.props.total !== 0 &&
      nextProps.currentPage === this.props.currentPage &&
      nextProps.total !== this.props.total) {
      this.props.onUpdate(count, currentPage, orderMod);
    }
  }

  render() {
    const {serverError, total, requestStatus, currentPage} = this.props;
    const errors = serverError ? [serverError] : [];
    const {count, orderMod} = this.state;
    const pages = Math.ceil(total / count);
    const {courses} = this.props;
    return (
      <div>
        <Notification errors={errors}/>
        <Paper zDepth={1} className={pages > 1 ? styles.CoursesContent : ''}>
          {
            <StatusSwitcher
              status={requestStatus}
              errorContent={errors}
              loadingContent={'Loading courses...'}
              loadingClass={'mt20'}
              success={
                <CoursesList courses={courses}
                             onRemoveCourse={this.props.onRemoveCourse}
                             onForceRemoveCourse={this.props.onForceRemoveCourse}
                             onCancelRemoveCourse={this.props.onCancelRemoveCourse}
                />
              }
            />
          }
        </Paper>
        <Pagination requestStatus={requestStatus}
                    pageCount={pages}
                    currentPage={currentPage - 1}
                    onPageChange={(e) => {
          const currentPage = e.selected + 1;
          this.props.onUpdate(count, currentPage, orderMod);
        }}/>
        <Divider hidden/>
      </div>
    );
  }
}

export default CoursesDashboard;
