export default function moneyFormat(val, currency) {
    if (currency)
        return new Intl.NumberFormat('en-US', {style: 'currency', currency}).format(val);
    return val.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,');
}
