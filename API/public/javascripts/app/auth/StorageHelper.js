const USER_FIELD = 'user';

export default class StorageHelper {
    static saveUser(user) {
        const userJSON = JSON.stringify(user);
        localStorage.setItem(USER_FIELD, userJSON);
    }

    static deleteUserInfo() {
        localStorage.removeItem(USER_FIELD);
    }

    static getToken() {
        const user = StorageHelper.getUser();
        if (!user)
            return null;

        return user.accessToken;
    }

    static getUser() {
        const userRow = localStorage.getItem(USER_FIELD);

        if (!userRow)
            return null;

        return JSON.parse(userRow);
    }
}
