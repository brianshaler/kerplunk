path = require 'path'

_ = require 'lodash'
Promise = require 'when'
docker = require 'docker-remote-api'

request = docker()

createContainer = (opt) ->
  deferred = Promise.defer()
  request.post '/containers/create', opt, (err, container) ->
    return deferred.reject err if err
    deferred.resolve container.Id
  deferred.promise

createImage = (opt) ->
  deferred = Promise.defer()
  request.post '/images/create', opt, (err, image) ->
    return deferred.reject err if err
    deferred.resolve image
  .end()
  deferred.promise

startContainer = (id) ->
  deferred = Promise.defer()
  request.post "/containers/#{id}/start", {json: {}}, (err, container) ->
    return deferred.reject err if err
    deferred.resolve id
  .end()
  deferred.promise

createAndStart = (opt) ->
  createContainer opt
  .then (id) ->
    startContainer id

pullAndCreate = (opt) ->
  console.log 'sry i have to pull', opt.json.Image
  imgOpt =
    qs:
      fromImage: opt.json.Image
  createImage imgOpt
  .then ->
    createAndStart opt

module.exports = (name, config) ->
  ports = {}
  if config.ports?.length > 0
    for port in config.ports
      ports[port] = [HostPort: String Math.floor 25000 + Math.random() * 1000]
  volumes = {}
  binds = []
  if config.volumes?.length > 0
    for volume in config.volumes
      hostPath = path.join "/data/#{name}", volume
      binds.push "#{hostPath}:#{volume}"
      volumes[volume] = {}
  createOpt =
    qs:
      name: name
    json:
      Image: config.image
      Volumes: volumes
      HostConfig:
        PortBindings: ports
        Binds: binds
  if config.cmd
    createOpt.json.Cmd = config.cmd
  #console.log 'opt', opt

  createAndStart createOpt
  .catch (err) ->
    if err.status == 404
      console.log 'caught error, going to try pulling'
      return pullAndCreate createOpt
    throw err
  .then (id) ->
    console.log 'successfully started container', id
    id
