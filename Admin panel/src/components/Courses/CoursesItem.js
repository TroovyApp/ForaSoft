import React, {Component} from 'react';
import {Label, Popup, Icon, Item, Grid, Divider, Header, List, Image} from 'semantic-ui-react';
import classnames from 'classnames';
import Scrollbars from 'react-custom-scrollbars';
import ReadMore from '../../components/common/text/ReadMore';

import SessionsModal from '../../components/Sessions/SessionsModal';
import ActionModal from '../../components/common/Modal/ActionModal';
import InfoModal from '../../components/common/Modal/InfoModal';
import UserChip from '../../components/common/User/UserChip';
import RaisedButton from 'material-ui/RaisedButton';

import DefaultCourseImage from '../../static/default_course.jpg';
import DefaultAvatarImage from '../../static/default_avatar.png';

import moneyFormat from '../../helpers/moneyFormat';

const styles = require('./CoursesItem.sass');

class CoursesItem extends Component {
    render() {
        const {course} = this.props;
        const {onRemoveCourse, onCancelRemoveCourse} = this.props;
        let image = course.courseIntroVideoPreviewUrl;
        if (!Boolean(image)) {
            image = course.courseImageUrl;
        }
        if (!Boolean(image)) {
            image = DefaultCourseImage;
        }
        return (
            <Grid.Row columns={2} key={course.id}>
                <Grid.Column mobile={16} tablet={11} computer={13}>
                    <Item.Group className={'ml5 mr10'}>
                        <Item className={styles.CourseItem}>
                            <Item.Image
                                src={image}
                                style={{maxWidth: '125px'}}
                                label={
                                    <Popup
                                        trigger={
                                            <Label
                                                corner="left"
                                                color={'red'}
                                                size="large"
                                                style={{
                                                    "textAlign": "left",
                                                    "paddingTop": "12px",
                                                    "paddingLeft": "10px"
                                                }}
                                                className={'invisible'}
                                            >
                                                {1}
                                            </Label>
                                        }
                                        content='Number of times this Course was reported (BETA)'
                                        inverted
                                    />
                                }
                                className={styles.CourseItemImage}
                            />
                            <Item.Content>
                                <Item.Header style={{marginTop: "-1px", width: '100%'}}>
                                    <div className="longString"
                                         style={{width: 'calc(100% - 141px)', marginRight: '10px', float: 'left'}}>
                                        <Popup
                                            trigger={<span>{course.title}</span>}
                                            content={course.title}
                                            position={'bottom left'}
                                            size={'small'}
                                            style={{maxWidth: '50%'}}
                                        />
                                    </div>
                                </Item.Header>
                                <Item.Meta>
                                    <UserChip user={course.creator}/>
                                </Item.Meta>
                                <Item.Description className={styles.Description}>
                                    <ReadMore children={course.description} lines={5}/>
                                </Item.Description>
                                <Item.Extra>
                                    {course.status === 3 ?
                                        <Label basic color={'orange'}>
                                            <Icon name={'archive'}/>
                                            <span>Archived course</span>
                                        </Label> : null}
                                </Item.Extra>
                            </Item.Content>
                        </Item>
                    </Item.Group>
                </Grid.Column>
                <Grid.Column mobile={16} tablet={5} computer={3} textAlign="center" style={{paddingRight: '20px'}}>
                    <ActionModal
                        trigger={<RaisedButton label="Delete" secondary={true} fullWidth={true}/>}
                        requestStatus={course.requestStatus}
                        lastError={course.lastError}
                        header={<Header icon='trash outline'
                                        content={`Are you sure you want to remove the course?`}/>}
                        statusContent={{
                            loadingContent: `Removing course in progress ...`
                        }}
                        onAccept={(e) => {
                            const isForceRemove = e.isForce;
                            onRemoveCourse(course.id, isForceRemove)
                        }}
                        onCancel={() => {
                            onCancelRemoveCourse(course.id)
                        }}
                    />
                    <Label tag size="small" className={classnames(styles.tag, styles.total)}>
                        Total: {moneyFormat(course.rawIncome, course.currency)}
                    </Label>
                    <Label tag size="small" className={classnames(styles.tag, styles.price)}>
                        Price: {moneyFormat(course.price, course.currency)}
                    </Label>
                    {course.subscribersCount > 0
                        ?
                        <InfoModal
                            trigger={
                                <Label tag size="small" className={classnames(styles.tag, styles.subscribers)}>
                                    Subscribers: {course.subscribersCount}
                                </Label>
                            }
                            header={<Header>Subscribers list</Header>}
                            content={
                                <Scrollbars autoHeight autoHeightMax={'70vh'}>
                                    <List verticalAlign='middle' className={styles.subscribersList}>
                                        {course.subscribers.map((s, index) => {
                                            return (
                                                <List.Item key={index} className={styles.subscriber}>
                                                    <Image avatar src={s.imageUrl ? s.imageUrl : DefaultAvatarImage}/>
                                                    <List.Content>
                                                        <List.Header>{s.name}</List.Header>
                                                    </List.Content>
                                                </List.Item>
                                            )
                                        })}
                                    </List>
                                </Scrollbars>
                            }
                        />
                        : <Label tag size="small" className={classnames(styles.tag, styles.subscribers, styles.empty)}>
                            Subscribers: {course.subscribersCount}
                        </Label>}
                    <Divider className={'invisible'}/>
                    <SessionsModal sessions={course.sessions}
                                   courseImage={course.courseImageUrl ? course.courseImageUrl : DefaultCourseImage}
                                   courseName={course.title}
                    />
                </Grid.Column>
            </Grid.Row>
        );
    }
}

export default CoursesItem;
