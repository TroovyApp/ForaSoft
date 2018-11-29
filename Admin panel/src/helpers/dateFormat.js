import moment from 'moment';

export default function dateFormat(val) {
  const format = 'D MMM. YYYY  h:mm a';
  return moment.unix(val).format(format);
}
