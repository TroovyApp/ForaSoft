import React, {Component} from 'react';
import REQUEST_STATUSES from '../../../constants/requestStatuses';
import StatusLoader from './StatusLoader';
import StatusError from './StatusError';

class StatusSwitcher extends Component {
  render() {
    const {status, permanentInitial} = this.props;
    const {
      errorHeader,
      errorContent,
      errorClass,
      loadingHeader,
      loadingContent,
      loadingClass
    } = this.props;
    const {success, initial} = this.props;
    switch (status) {
      case REQUEST_STATUSES.REQUESTED:
        return <div>
          {permanentInitial ? initial : null}
          <StatusLoader header={loadingHeader}
                        content={loadingContent}
                        className={loadingClass}/>
        </div>;
      case REQUEST_STATUSES.FAILED:
      case REQUEST_STATUSES.ERROR:
        return <div>
            {permanentInitial ? initial : null}
            <StatusError header={errorHeader}
                         className={errorClass}
                         content={errorContent}/>
          </div>;
      case REQUEST_STATUSES.SUCCEEDED:
        return success;
      case REQUEST_STATUSES.NONE:
      default:
        return initial;
    }
  }
}

StatusSwitcher.defaultProps = {
  status: REQUEST_STATUSES.NONE,
  permanentInitial: false,
  initial: <div></div>,
  errorHeader: 'Error',
  errorContent: 'Some error',
  errorClass: 'pr20 pl20',
  loadingHeader: 'Loading',
  loadingContent: 'Loading...',
  loadingClass: '',
  success: <div>Success!</div>
};

export default StatusSwitcher;
