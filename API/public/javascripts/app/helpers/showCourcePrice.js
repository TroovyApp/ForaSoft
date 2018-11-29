export default () => {
    const {courseCurrency, coursePrice} = config;
    const coursePriceString = new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: courseCurrency
    }).format(coursePrice);
    $('.subscribe-btn').text(`subscribe ${coursePriceString}`);
};