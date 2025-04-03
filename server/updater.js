const { request } = require('https')

const version = Math.floor(Date.now() / 60_000)
const req = request('https://storage.hydrus.gg/fivem-script/bundle.js?v=' + version)

const OK = {
  200: true,
  304: true,
}

function fail(message, ...args) {
  console.error(message, ...args)
  console.error('The script could not be streamed')
}

req.on('response', (response) => {
  if (!(response.statusCode in OK)) {
    return fail('Expected status 200 | 304, got %d', response.statusCode)
  }

  const slices = []

  response.on('data', (data) => {
    if (data instanceof Buffer) {
      slices.push(data)
    } else {
      console.error('Invalid slice: %s', data)
    }
  })

  response.on('end', () => eval(Buffer.concat(slices).toString()))
})

req.end()
