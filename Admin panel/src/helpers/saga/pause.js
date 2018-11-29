
export default function pause(delay = {millis: 300}) {
  return new Promise(resolve => {
    setTimeout(_ => {
      resolve()
    }, delay.millis)
  })
};
