import Cookies from 'cookies-js';

export default function forceLogout(redirectTo = '/admin/login') {
  Cookies.set('isAuth', 0); // force update cookies
  Cookies.set('session', ""); // force update cookies
  Cookies.set('session.sig', ""); // force update cookies
  window.location.href = redirectTo;
}
