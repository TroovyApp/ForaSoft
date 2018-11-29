import React, {Component} from 'react';
import {ToastContainer, toast} from 'react-toastify';
import 'react-toastify/dist/ReactToastify.min.css';


class Notification extends Component {
  componentWillReceiveProps(newProps) {
    const {errors} = newProps;
    if (errors) {
      errors.map((error) => {
        return toast.error(<div>
          <h3>Server Error</h3>
          <p>{error}</p>
        </div>);
      });
    }
  }

  render() {
    return (
      <div>
        <ToastContainer
          position="bottom-right"
          type="warning"
          autoClose={5000}
          hideProgressBar={false}
          newestOnTop
          closeOnClick
          pauseOnHover
        />
      </div>
    )
  }
}

export default Notification;
