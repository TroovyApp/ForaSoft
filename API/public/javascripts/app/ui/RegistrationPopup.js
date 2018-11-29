import popups from 'popups';
import BasePopup from './BasePopup';
import './RegistrationPopup.css';
import isEmailRight from '../helpers/isEmailRight';
import PhoneNumberPopup from "./PhoneNumberPopup";

export default class RegistrationPopup extends BasePopup {
    static show(onSubmit, onBack) {
        return popups.window({
            mode: 'modal',
            title: '',
            content: `
            <div class='title'><div class='back' id='back'></div>Registration</div>
            <div class='body'>
                <div class='register-container'>
                <div class='field'>
                    <label for='name' class='label'>Name</label>
                    <input type='text' class='input' id='name'/>
                    <div class='error-label hidden name'>Please, enter your name</div>
                </div>
                <div class='field'>
                    <label for='email' class='label'>Email</label>
                    <input type='text' class='input' id='email'/>
                    <div class='error-label hidden email'>Please, enter a valid email</div>
                </div>
                </div>
                <button class='subscribe-btn register-btn'>
                    Next
                </button>
                <div class='hidden error-label registration common' id='server-error'></div>
                ${RegistrationPopup.getLoaderLayout()}
            </div>
            `,
            onClose: function () {
                BasePopup.hideLoader();
            },
            onOpen: function () {
                $('.register-btn').on('click', () => {
                    if (hasValidationErrors())
                        return;

                    onSubmit(getData());
                    RegistrationPopup.showLoader();
                });
                $('.input').on('keydown', e => {
                    $(e.target).parent().find('.error-label').addClass('hidden');
                });
                $('#back').click(onBack);
            },
            force: true,
            flagCloseByEsc: false,
            flagCloseByOverlay: false,
            flagShowCloseBtn: false
        });
    }

    static showNetworkError(err) {
        $('.registration#server-error')
            .text(err)
            .removeClass('hidden');
        RegistrationPopup.hideLoader();
    }

    static hideNetworkError() {
        $('.registration#server-error').addClass('hidden');
    }
}

function hasValidationErrors() {
    const {name, email} = getData();
    if (name.length === 0)
        $('.error-label.name').removeClass('hidden');

    if (email && !isEmailRight(email))
        $('.error-label.email').removeClass('hidden');

    return name.length === 0 || (email && !isEmailRight(email));
}

function getData() {
    const name = ($('#name').val() || '').trim();
    const email = ($('#email').val() || '').trim();
    return {name, email};
}

