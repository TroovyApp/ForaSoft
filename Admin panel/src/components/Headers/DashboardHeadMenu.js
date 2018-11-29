import React, {Component} from 'react';
import classNames from 'classnames';
import PeopleIcon from 'material-ui/svg-icons/social/people';
import CoursesIcon from 'material-ui/svg-icons/social/school';
import WithdrawalIcon from 'material-ui/svg-icons/action/payment';
import ExitIcon from 'material-ui/svg-icons/action/input';
import {Grid} from 'semantic-ui-react';

import FloatingActionButton from 'material-ui/FloatingActionButton';
import {BottomNavigation, BottomNavigationItem} from 'material-ui/BottomNavigation';

import {NavLink} from 'react-router-dom';

const styles = require('./DashboardHeadMenu.sass');


class DashboardHeadMenu extends Component {
  state = {selected: 0};

  select(index) {
    this.setState({selected: index});
  };

  render() {
    return (
      <Grid verticalAlign="middle">
        <Grid.Row columns={3} stretched style={{"height": "85px"}}>
          <Grid.Column tablet={3} computer={2} only="tablet" style={{height: "100%"}}>
            <div className={classNames([styles.Link, styles.logo])}>
            </div>
          </Grid.Column>
          <Grid.Column mobile={13} tablet={12} computer={11}>
            <div>
              <BottomNavigation selectedIndex={this.state.selected} className="colorBgNone"
                                style={{"display": "block", "minWidth": "520px"}}>
                <NavLink to={'/admin/dashboard/users'}
                         activeClassName={styles.LinkActive}
                         className={styles.Link}>
                  <BottomNavigationItem
                    label="Users"
                    icon={<PeopleIcon/>}
                    onClick={() => this.select(0)}
                  />
                </NavLink>
                <NavLink to={'/admin/dashboard/courses'}
                         activeClassName={styles.LinkActive}
                         className={styles.Link}>
                  <BottomNavigationItem
                    label="Courses"
                    icon={<CoursesIcon/>}
                    onClick={() => this.select(1)}
                  />
                </NavLink>
                <NavLink to={'/admin/dashboard/withdrawal'}
                         activeClassName={styles.LinkActive}
                         className={styles.Link}>
                  <BottomNavigationItem
                    label="Withdrawal Requests"
                    icon={<WithdrawalIcon/>}
                    onClick={() => this.select(2)}
                  />
                </NavLink>
              </BottomNavigation>
            </div>
          </Grid.Column>
          <Grid.Column mobile={3} tablet={1} computer={3} textAlign="right">
            <FloatingActionButton
              mini={true}
              style={{"width": "40px"}}
              className={styles.Logout}
              onClick={this.props.onLogout}>
              <ExitIcon/>
            </FloatingActionButton>
          </Grid.Column>
        </Grid.Row>
      </Grid>
    );
  }
}

export default DashboardHeadMenu;
