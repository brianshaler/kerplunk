_ = require 'lodash'
Promise = require 'when'
dockerode = require 'dockerode'

docker = dockerode()

module.exports = (name) ->
  Promise.promise (resolve, reject) ->
    docker.listContainers {all: false}, (err, data) ->
      return reject err if err
      resolve data
  .then (containers) ->
    Name = "/#{name}"
    _.find containers, (container) ->
      0 <= container.Names.indexOf Name
  .catch (err) ->
    console.log 'getExistingContainer error'
    console.log err?.stack ? err
    throw err
