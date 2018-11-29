import popups from 'popups';
import './PhoneNumberPopup.css';
import 'intl-tel-input/build/js/utils';

import BasePopup from './BasePopup';

export default class PhoneNumberPopup extends BasePopup {
    static show(onSubmit) {
        return popups.window({
            mode: 'modal',
            title: '',
            content: `
            <div class='title'>Log in to continue</div>
            <div class='body'>
            <label class='label' for='phone'>Phone number</label>
                <input type='tel' id='phone' class='input'/>
                <div class='hidden error-label auth' id='local-error'>Please, enter a valid phone number</div>
                <div class='hidden error-label auth common' id='server-error'></div>
                <button class='subscribe-btn send-code-btn'>
                    Login
                </button>
                <div class="link-container">
                    <a href="/terms-and-conditions">Terms and Conditions</a>
                    <a href="/privacy">Privacy Policy</a>
                </div>
                ${PhoneNumberPopup.getLoaderLayout()}
            </div>
            `,
            onClose: function () {
                BasePopup.hideLoader();
            },
            onOpen: function () {
                const $phone = $('#phone');
                $phone.intlTelInput({
                    separateCountryCode: true
                });
                $phone.on('keydown', () => {
                    PhoneNumberPopup.hideError();
                    PhoneNumberPopup.hideNetworkError();
                });
                $('.send-code-btn').click(() => {
                    const $phone = $('#phone');
                    if ($phone.intlTelInput('getValidationError'))
                        return PhoneNumberPopup.showError();

                    onSubmit($phone);
                    PhoneNumberPopup.showLoader();
                });
            },
            force: true
        });
    }

    static showError() {
        $('.auth#local-error').removeClass('hidden');
    }

    static hideError() {
        $('.auth#local-error').addClass('hidden');
    }

    static showNetworkError(err) {
        $('.auth#server-error')
            .text(err)
            .removeClass('hidden');
        PhoneNumberPopup.hideLoader();
    }

    static hideNetworkError() {
        $('.auth#server-error').addClass('hidden');
    }
}