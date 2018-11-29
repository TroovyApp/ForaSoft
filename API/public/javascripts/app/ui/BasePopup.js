import './BasePopup.css';

export default class BasePopup {
    static showNetworkError() {

    }

    static hideNetworkError() {

    }

    static getLoaderLayout() {
        return `
        <div class='spinner hidden'>
            <div class='bounce1'></div>
            <div class='bounce2'></div>
            <div class='bounce3'></div>
        </div>
        `;
    }

    static showLoader() {
        $('.spinner').removeClass('hidden');
    }

    static hideLoader() {
        $('.spinner').addClass('hidden');
    }
}