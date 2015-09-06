Promise = require 'when'
docker = require 'docker-remote-api'

request = docker()

module.exports = (id) ->
  deferred = Promise.defer()
  opt =
    json: true
  request.get "/containers/#{id}/json", opt, (err, container) ->
      return deferred.reject err if err
      deferred.resolve container
  deferred.promise
