import uuid from 'uuid/v4';

import StorageHelper from './StorageHelper';
import uiConnector from '../ui/UIConnector';
import makeRequest from '../ApiClient';
import hasError from '../helpers/isError';
import EventEmitter from 'events';


export default class AuthModule extends EventEmitter {
    constructor() {
        super();
        this.executePromise = null;
        this.appToken = null;
        this.dialCode = null;
        this.phoneNumber = null;
        uiConnector.showAuthContainer();
        this._bindAuthContainer();
    }

    _bindAuthContainer() {
        $('#logout').off('click').on('click', () => {
            this._onLogout();
        });
    }

    async _onLogout() {
        if (!this.isAuth())
            return;

        await makeRequest({
            method: 'post',
            path: '/users/logout'
        });
        StorageHelper.deleteUserInfo();
        uiConnector.showAuthContainer();
        this.emit('logout');
    }

    isAuth() {
        return Boolean(StorageHelper.getToken());
    }

    authenticate() {
        this.appToken = uuid();
        return new Promise((res, rej) => {
            this.executePromise = res;
            uiConnector.showPhoneNumberPopup(this._sendCode.bind(this));
        });
    }

    async _sendCode($el) {
        const fullNumber = $el.intlTelInput('getNumber');
        const dialCode = `+${$el.intlTelInput('getSelectedCountryData').dialCode}`;
        const phoneNumber = fullNumber.replace(dialCode, '');
        this.dialCode = dialCode;
        this.phoneNumber = phoneNumber;

        const response = await makeRequest({
            method: 'post',
            path: '/users/verify',
            data: {
                appGeneratedToken: this.appToken,
                dialCode,
                phoneNumber
            }
        });
        if (hasError(response))
            return;

        uiConnector.showVerificationCodePopup(this._verifyCode.bind(this), () => {
            uiConnector.showPhoneNumberPopup(this._sendCode.bind(this));
        });
    }

    async _verifyCode(verifyCode) {
        const response = await makeRequest({
            method: 'post',
            path: '/users/confirm',
            data: {
                appGeneratedToken: this.appToken,
                confirmationCode: verifyCode
            }
        });
        const {status, data} = response;
        if (status !== 200 || data.code !== 200)
            uiConnector.clearCode();

        if (hasError(response))
            return;

        if (Object.keys(data.result).length > 0) {
            return this._onLogin(data.result);
        }

        uiConnector.showRegistrationPopup(this._register.bind(this), () => {
            uiConnector.showPhoneNumberPopup(this._sendCode.bind(this));
        });
    }


    _onLogin(userResponse) {
        StorageHelper.saveUser(userResponse);

        uiConnector.showAuthContainer();
        this._bindAuthContainer();

        if (this.executePromise)
            this.executePromise();
    }

    async _register(userData) {
        const response = await makeRequest({
            method: 'post',
            path: '/users',
            data: {
                name: userData.name,
                email: userData.email,
                phoneNumber: this.phoneNumber,
                dialCode: this.dialCode,
                appGeneratedToken: this.appToken
            }
        });

        if (hasError(response))
            return;

        this._onLogin(response.data.result);
    }
}

