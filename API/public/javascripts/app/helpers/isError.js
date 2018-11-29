import uiConnector from '../ui/UIConnector';

export default function hasError(response) {
    const {data, status} = response;

    if (status !== 200)
        uiConnector.showNetworkError('Unexpected server error. Please try again later or contact support');

    if (data.code === 502)
        uiConnector.showNetworkError(`SMS service error: ${data.error}`);

    if (data.code !== 200)
        uiConnector.showNetworkError(data.error);

    return (status !== 200 || data.code !== 200);
}
