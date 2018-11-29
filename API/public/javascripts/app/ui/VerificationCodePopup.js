import popups from 'popups';
import BasePopup from './BasePopup';
import './VerificationCodePopup.css';
import PhoneNumberPopup from "./PhoneNumberPopup";

const BACKSPACE_CODE = 8;

export default class VerificationCodePopup extends BasePopup {
    static show(onSubmit, onBack) {
        return popups.window({
            mode: 'modal',
            title: '',
            content: `
            <div class='title'><div class='back' id='back'></div>Verification</div>
            <div class='body'>
            <div class='info'>Please enter the code sent to your phone number below:</div>
                <div id='verify-input-container' class='verify-input-container'>
                    <input id='code-0' class='code-input' maxlength='1' type="tel"/>
                    <input id='code-1' class='code-input' maxlength='1' type="tel"/>
                    <input id='code-2' class='code-input' maxlength='1' type="tel"/>
                    <input id='code-3' class='code-input' maxlength='1' type="tel"/>
                    <input id='code-4' class='code-input' maxlength='1' type="tel"/>
                </div>
                <div class='hidden error-label code common' id='server-error'></div>
                ${VerificationCodePopup.getLoaderLayout()}
            </div>
            `,
            onOpen: function () {
                const $inputs = $('.code-input');
                $inputs.on('input', (e) => {
                    VerificationCodePopup.hideNetworkError();
                    const {value} = e.target;

                    if (value.length === 0) {
                        $(e.target).removeClass('full');
                        return;
                    }

                    $(e.target).addClass('full');
                    $(e.target).next().focus();

                    if (!isVerifyCodeInsert())
                        return;

                    VerificationCodePopup.showLoader();
                    onSubmit(getVerifyCode());
                });

                $inputs.on('keydown', e => {
                    if (e.keyCode !== BACKSPACE_CODE)
                        return;

                    if ($(e.target).val().length === 0) {
                        $(e.target).prev().focus();
                    }

                });

                $('#code-0').focus();
                $('#back').click(onBack);
            },
            onClose: function () {
                BasePopup.hideLoader();
            },
            force: true,
            flagCloseByEsc: false,
            flagCloseByOverlay: false,
            flagShowCloseBtn: false
        });
    }

    static showNetworkError(err) {
        $('.code#server-error')
            .text(err)
            .removeClass('hidden');
        VerificationCodePopup.hideLoader();
    }

    static hideNetworkError() {
        $('.code#server-error').addClass('hidden');
    }

    static clear() {
        $('.code-input').val('').removeClass('full');
        $('#code-0').focus();
    }
}

function isVerifyCodeInsert() {
    let isFull = true;
    $('.code-input').each((index, input) => {
        if ($(input).val().length === 0)
            isFull = false;
    });
    return isFull;
}

function getVerifyCode() {
    let code = '';
    $('.code-input').each((index, input) => {
        code += $(input).val();
    });
    return code;
}
