path = require 'path'

_ = require 'lodash'
Promise = require 'when'

dockerode = require 'dockerode'

docker = dockerode()

pullImage = (name) ->
  Promise.promise (resolve, reject) ->
    docker.pull name, (err, stream) ->
      return reject err if err
      docker.modem.followProgress stream, (err, output) ->
        return reject err if err
        resolve output
      , (event) ->
        console.log 'onProgress event', event

runContainer = (opt) ->
  console.log 'runContainer', opt
  Promise.promise (resolve, reject) ->
    docker.createContainer opt, (err, container) ->
      return reject err if err
      container.start (err, data) ->
        return reject err if err
        resolve container.id # lowercase .id? nice.

deleteContainer = (id) ->
  container = docker.getContainer id
  Promise.promise (resolve, reject) ->
    container.remove (err, data) ->
      return reject err if err
      resolve data
  .then (data) ->
    console.log 'deleteContainer result:', data
    id
  .catch (err) ->
    console.log 'deleteContainer failed'
    console.log err?.stack ? err
    throw err

pullAndCreate = (opt) ->
  console.log 'sry i have to pull', opt.Image
  pullImage opt.Image
  .then (img) ->
    console.log 'pulled image', img
    runContainer opt

deleteAndCreate = (opt) ->
  deleteContainer opt.name
  .then ->
    runContainer opt

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
    Image: config.image
    name: name
    Volumes: volumes
    HostConfig:
      PortBindings: ports
      Binds: binds
  if config.cmd
    createOpt.Cmd = config.cmd
  #console.log 'opt', opt

  runContainer createOpt
  .then (data) ->
    console.log 'ranContainer', data
    data
  .catch (err) ->
    if err.statusCode == 404
      console.log 'caught error, going to try pulling'
      return pullAndCreate createOpt
    if err.statusCode == 409
      return deleteAndCreate createOpt
    console.log 'runContainer err status', err?.status ? err
    throw err
  .then (id) ->
    console.log 'successfully started container', id
    id
