import {create} from 'apisauce';
import StorageHelper from './auth/StorageHelper';

class ApiClient {
    constructor() {
        this.client = create({
            baseURL: config.API_URL,
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'json'
            }
        });
    }

    makeRequest(httpRequest) {
        const {method, path} = httpRequest;
        this._addToken();
        return this.client[method](path, this._formatRequestParams(httpRequest));
    }

    _formatRequestParams({params, data}) {
        if (params)
            return params;

        if (data)
            return data;
    }

    _addToken() {
        this.client.addRequestTransform(request => {
                const token = StorageHelper.getToken();
                if (!token)
                    return;
                if (!request.params)
                    request.params = {};
                request.params.accessToken = token;
            }
        );
    }
}

const _apiClient = new ApiClient();

export default requestOptions => {
    return _apiClient.makeRequest(requestOptions);
}
