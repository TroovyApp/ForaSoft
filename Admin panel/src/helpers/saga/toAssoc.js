import REQUEST_STATUSES from '../../constants/requestStatuses';

export default function mapToAssocWithRequestInfo(items) {
  const newItems = {};
  items.map((item) => {
    item.requestStatus = REQUEST_STATUSES.NONE;
    item.lastError = null;
    newItems[item.id] = item;
  });
  return newItems;
};
