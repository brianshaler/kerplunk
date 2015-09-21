getExistingContainer = require './getExistingContainer'
inspectContainer = require './inspectContainer'
runContainer = require './runContainer'

module.exports = (service) ->
  {
    System
    pluginName
    serviceName
    serviceConfig
  } = service
  containerName = "#{process.env.KERPLUNK_ID}-#{pluginName}-#{serviceName}"

  getExistingContainer containerName
  .then (container) ->
    if container
      inspectContainer container.Id
    else
      runContainer containerName, serviceConfig
      .then inspectContainer
  .then (container) ->
    ports = {}

    for internal, settings of container.NetworkSettings.Ports
      if settings?[0]?.HostPort
        ports[internal] = settings[0].HostPort

    pluginName: pluginName
    serviceName: serviceName
    ip: container.NetworkSettings.Gateway
    ports: ports
  .catch (err) ->
    console.log 'setupService error'
    console.log err?.stack
    throw err
