import React, {Component} from 'react';
import classnames from 'classnames';
import ReactPaginate from 'react-paginate';

const styles = require('./Pagination.sass');


class Pagination extends Component {

  render() {
    const {className} = this.props;
    const invisibleClass = this.props.pageCount <= 1 ? 'invisible' : '';

    let {currentPage} = this.props;

    return <div className={classnames(styles.PaginationContainer, className, invisibleClass)}>
      <ReactPaginate previousLabel={"❮"}
                     nextLabel={"❯"}
                     breakLabel={<span>...</span>}
                     pageClassName={styles.PaginationItem}
                     activeClassName={styles.PaginationItem__Active}
                     pageCount={this.props.pageCount}
                     initialPage={currentPage}
                     forcePage={currentPage}
                     marginPagesDisplayed={2}
                     pageRangeDisplayed={5}
                     onPageChange={this.props.onPageChange}
                     containerClassName={classnames(styles.Pagination)}
                     subContainerClassName={"pages pagination"}
                     disabledClassName={styles.PaginationControl__disable}
                     previousLinkClassName={styles.PaginationControl}
                     nextLinkClassName={styles.PaginationControl}
                     hrefBuilder={(page) => {
                       return `?page=${page}`;
                     }}
      />
    </div>;
  }
}

export default Pagination;
