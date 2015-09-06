_ = require 'lodash'
Promise = require 'when'
docker = require 'docker-remote-api'

request = docker()

module.exports = (name) ->
  deferred = Promise.defer()
  request.get '/containers/json',
    {json: true}
    (err, containers) ->
      return deferred.reject err if err
      deferred.resolve _.find containers, (container) ->
        -1 != container.Names.indexOf "/#{name}"
  deferred.promise
