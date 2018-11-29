import popups from 'popups';
import StorageHelper from '../auth/StorageHelper';
import BasePopup from './BasePopup';
import isEmailRight from '../helpers/isEmailRight';

import './StripeCardPopup.css';

export default class StripeCardPopup extends BasePopup {

    static show(stripe, onSubmit, onCheckCoupon) {
        return popups.window({
            mode: 'modal',
            title: '',
            content: `
            <div class='title'>Buy workshop</div>
            <div class='body'>            
                <form id='payment-form'>
                    <div id='card' class='form-row'>
                        <div>
                            <label for='card-number' class='label'>Card number</label>
                            <div id='card-number' class='card-number'></div>
                            <div class="error-label card-number"></div>
                        </div>
                        <div class="two-col">
                            <div class="field">
                                <label for='card-expiration' class='label'>Expiration date</label>
                                <div id='card-expiry' class='card-expiration'></div>
                            </div>
                            <div class="field">
                                <label for='card-cvc' class='label'>CVC</label>
                                <div id='card-cvc' class='card-cvc'></div>
                            </div>
                        </div>
                        <div class="error-label card-errors common"></div>
                    </div>
                    <div class='field'>
                        <label for='email' class='label'>Email for invoicing</label>
                        <input type='text' class='input' id='email' value='${StorageHelper.getUser().email}'/>
                        <div class='error-label hidden email'>Please, enter a valid email</div>
                    </div>
                    <div class='field'>
                        <label for='coupon' class='label'>Coupon</label>
                        <input type='text' class='input' id='coupon'/>
                        <div class='error-label hidden coupon'>Coupon not found</div>
                    </div>
                    <div class='error-label subscribe common' id='server-error'></div>
                    <button class='subscribe-btn send-code-btn'>
                        Pay
                    </button>
                    </div>
                </form>               
                ${StripeCardPopup.getLoaderLayout()} 
                </div>            
            `,
            onClose: function () {
                BasePopup.hideLoader();
            },
            onOpen: function () {
                const elements = stripe.elements();

                StripeCardPopup.cardNumber = elements.create('cardNumber', {
                    style: StripeCardPopup.getStyle()
                });
                StripeCardPopup.cardNumber.mount('#card-number');

                StripeCardPopup.cardExpiry = elements.create('cardExpiry', {
                    style: StripeCardPopup.getStyle()
                });
                StripeCardPopup.cardExpiry.mount('#card-expiry');

                StripeCardPopup.cardCvc = elements.create('cardCvc', {
                    style: StripeCardPopup.getStyle()
                });
                StripeCardPopup.cardCvc.mount('#card-cvc');

                StripeCardPopup.addEventListenersForCardFields();

                StripeCardPopup.cardNumber.addEventListener('ready', function (event) {
                    StripeCardPopup.cardNumber.focus();
                });
                const form = document.getElementById('payment-form');
                form.addEventListener('submit', function (event) {
                    event.preventDefault();
                    if (hasValidationErrors())
                        return;

                    StripeCardPopup.showLoader();
                    if (StripeCardPopup.discount !== 100) {
                        stripe.createToken(StripeCardPopup.cardNumber)
                            .then(stripeCallback(onSubmit));
                        return;
                    }
                    onSubmit(null, $('#email').val(), $('#coupon').val());
                });
                const couponField = document.getElementById('coupon');
                couponField.addEventListener('blur', function (event) {
                    event.preventDefault();

                    onCheckCoupon(this.value);
                });
                $('.input').on('keydown', e => {
                    $(e.target).next('.error-label').text('');
                });
            },
            force: true
        });
    }

    static getStyle() {
        return {
            base: {
                color: '#32325d',
                lineHeight: '18px',
                fontSmoothing: 'antialiased',
                fontSize: '16px',
                '::placeholder': {
                    color: '#aab7c4'
                }
            },
            invalid: {
                color: 'rgb(237, 106, 122)',
                iconColor: 'rgb(237, 106, 122)'
            }
        };
    }

    static showNetworkError(err) {
        $('.subscribe#server-error')
            .text(err)
            .removeClass('hidden');
        StripeCardPopup.hideLoader();
    }

    static hideNetworkError() {
        $('.subscribe#server-error').text('');
    }

    static setDiscount(discount) {
        if (discount === 100) {
            $('#card').addClass('hidden');
            StripeCardPopup.cardCvc.removeEventListener('change');
            StripeCardPopup.cardNumber.removeEventListener('change');
            StripeCardPopup.cardExpiry.removeEventListener('change');
        } else if (StripeCardPopup.discount === 100 && discount !== 100) {
            $('#card').removeClass('hidden');
            StripeCardPopup.addEventListenersForCardFields();
        }
        StripeCardPopup.discount = discount;
    }

    static addEventListenersForCardFields() {
        StripeCardPopup.cardNumber.addEventListener('change', onCardFieldChange('card-number'));

        StripeCardPopup.cardExpiry.addEventListener('change', onCardFieldChange('card-errors'));

        StripeCardPopup.cardCvc.addEventListener('change', onCardFieldChange('card-errors'));
    };

}

function onCardFieldChange(field) {
    return function (event) {
        const errorContainer = $(`.${field}.error-label`);
        StripeCardPopup.hideNetworkError();
        if (event.error) {
            errorContainer.text(event.error.message);
        } else {
            errorContainer.text('');
        }
    }
}

function hasValidationErrors() {
    const email = $('#email').val();

    if (!isEmailRight(email)) {
        const errorLabel = $('.error-label.email');
        errorLabel.removeClass('hidden');
        errorLabel.text('Please, enter a valid email')
    }

    return !isEmailRight(email);
}


function stripeCallback(onSubmit) {
    return function (result) {
        if (result.error) {
            const errorContainer = $('.subscribe#server-error');
            errorContainer.text(result.error.message);
            StripeCardPopup.hideLoader();
        } else {
            onSubmit(result.token, $('#email').val(), $('#coupon').val());
        }
    }
}