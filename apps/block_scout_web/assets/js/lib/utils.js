import debounce from 'lodash.debounce'

export function batchChannel (func) {
  let msgs = []
  const debouncedFunc = debounce(() => {
    func.apply(this, [msgs])
    msgs = []
  }, 1000, { maxWait: 5000 })
  return (msg) => {
    msgs.push(msg)
    debouncedFunc()
  }
}

export function showLoader (isTimeout, loader) {
  if (isTimeout) {
    const timeout = setTimeout(function () {
      loader.removeAttr('hidden')
      loader.show()
    }, 100)
    return timeout
  } else {
    loader.hide()
    return null
  }
}

export function fullPath (path) {
  const networkPath = document.body.dataset.networkPath || '/'
  return `${networkPath}${path}`.replace('//', '/')
}
