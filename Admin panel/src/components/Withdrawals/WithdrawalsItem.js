import React, {Component} from 'react';
import UserCard from '../../components/common/User/UserCard';
import ActionModal from '../../components/common/Modal/ActionModal';
import RaisedButton from 'material-ui/RaisedButton';
import {Header} from 'semantic-ui-react';

import moneyFormat from '../../helpers/moneyFormat';

import {
    TableRow,
    TableRowColumn
} from 'material-ui/Table';

const styles = require('./Withdrawals.sass');


class WithdrawalsItem extends Component {
    render() {
        const {withdrawal} = this.props;
        const {isApproved} = withdrawal;
        const {user} = withdrawal;
        return (<TableRow>
                <TableRowColumn>
                    <UserCard image={user.imageUrl} name={user.name} className={styles.UserProfile}/>
                </TableRowColumn>
                <TableRowColumn className={"text-center"} style={{width: '120px'}}>
                    {user.phoneNumber ? `${user.dialCode}${user.phoneNumber}` : 'not connected'}
                </TableRowColumn>
                <TableRowColumn className={"text-center"} style={{width: '250px'}}>
                    {withdrawal.bankAccountNumber}
                </TableRowColumn>
                <TableRowColumn className={"text-center"} style={{width: '110px'}}>
                    {moneyFormat(withdrawal.amountCredits, withdrawal.currency)}
                </TableRowColumn>
                <TableRowColumn style={{width: '180px'}} className={"text-center"}>
                    {
                        withdrawal.isApproved ?
                            <div className={styles.approvedLabel} style={{width: '100px'}}>Approved</div>
                            :
                            <div>
                                <ActionModal
                                    trigger={<RaisedButton label={'Approve'} primary={true} style={{width: '100px'}}/>}
                                    requestStatus={withdrawal.requestStatus}
                                    lastError={withdrawal.lastError}
                                    header={<Header icon='money'
                                                    content={`Are you sure you want to approve the withdrawal request?`}/>
                                    }
                                    statusContent={{
                                        loadingContent: `Approving in progress ...`
                                    }}
                                    onAccept={(e) => {
                                        this.props.onApproveWithdrawal(withdrawal.id, withdrawal.isApproved)
                                    }}
                                    onCancel={() => {
                                        this.props.onCancelApproveWithdrawal(withdrawal.id)
                                    }}
                                />
                            </div>
                    }
                </TableRowColumn>
            </TableRow>
        );
    }
}

export default WithdrawalsItem;


