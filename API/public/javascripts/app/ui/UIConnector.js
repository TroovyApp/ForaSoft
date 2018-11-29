import PhoneNumberPopup from './PhoneNumberPopup';
import VerificationCodePopup from './VerificationCodePopup';
import RegistrationPopup from './RegistrationPopup';
import StripeCardPopup from './StripeCardPopup';
import ContentListener from './ContentListener';
import CarouselManager from './CarouselManager';

import StorageHelper from '../auth/StorageHelper';
import './AuthContainer.css';

const defaultAvatar = '/static/img/default_avatar.png';

const popupsRegistry = {
    PHONE: PhoneNumberPopup,
    VERIFY_CODE: VerificationCodePopup,
    REGISTRATION: RegistrationPopup,
    STRIPE: StripeCardPopup
};


class UIConnector {
    constructor() {
        this.currentPopupHandler = null;
        this.carouselManager = new CarouselManager();
    }

    showPhoneNumberPopup(onSubmit) {
        PhoneNumberPopup.show(onSubmit);
        this.currentPopupHandler = popupsRegistry.PHONE;
    }

    showVerificationCodePopup(onSubmit, onBack) {
        VerificationCodePopup.show(onSubmit, onBack);
        this.currentPopupHandler = popupsRegistry.VERIFY_CODE;
    }

    showRegistrationPopup(onSubmit, onBack) {
        RegistrationPopup.show(onSubmit, onBack);
        this.currentPopupHandler = popupsRegistry.REGISTRATION;
    }

    showStripeCardPopup(stripe, onSubmit, onCheckCoupon) {
        StripeCardPopup.show(stripe, onSubmit, onCheckCoupon);
        this.currentPopupHandler = popupsRegistry.STRIPE;
    }

    clearCode() {
        if (this.currentPopupHandler !== popupsRegistry.VERIFY_CODE)
            return;
        this.currentPopupHandler.clear();
    }

    showNetworkError(err) {
        this.currentPopupHandler.showNetworkError(err);
    }

    _hide() {
        if (this.currentPopupHandler)
            $('#popupS-overlay').click();
        this.currentPopupHandler = null;
    }

    showAuthContainer() {
        const user = StorageHelper.getUser();
        const $container = $('#auth-container');

        if (!user)
            return $container.html('');

        const avatarStyles = `background-image: url(${user.imageUrl ? user.imageUrl : defaultAvatar})`;

        const content = `
            <!--<div class="avatar" style="${avatarStyles}"/>-->
            <div class="logout" id="logout" role="button">Log out</div>
        `;

        $container.html(content);
    }

    setDiscount(discount) {
        if (this.currentPopupHandler !== popupsRegistry.STRIPE)
            return;

        this.currentPopupHandler.setDiscount(discount);
    }
}

export default new UIConnector();