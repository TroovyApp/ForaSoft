export const editItem = function (items, itemId, newData, status) {
  const newItems = Object.assign({}, items);
  newItems[itemId] = Object.assign({}, items[itemId], newData, {requestStatus: status});
  return newItems;
};

export const removeItem = function (items, itemId) {
  const newItems = Object.assign({}, items);
  delete newItems[itemId];
  return newItems;
};

export default {
  editItem,
  removeItem
};