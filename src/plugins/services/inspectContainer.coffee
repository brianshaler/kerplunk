Promise = require 'when'
dockerode = require 'dockerode'

docker = dockerode()

module.exports = (id) ->
  container = docker.getContainer id
  Promise.promise (resolve, reject) ->
    container.inspect (err, data) ->
      return reject err if err
      # console.log 'inspected', data
      resolve data
  .catch (err) ->
    console.log 'inspectContainer error', id
    console.log err?.stack ? err
    throw err
