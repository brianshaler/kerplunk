Promise = require 'when'

getServices = require './services/getServices'
setupPlugin = require './setupPlugin'

module.exports = (System, config) ->
  SystemReference = System.getProxy config.name, config.isCore
  #console.log 'getServices', config
  getServices System, config
  .then (services) ->
    #console.log 'save services', services
    for service in services
      SystemReference.setService service.serviceName, service.ip, service.ports
  .then ->
    setupPlugin config, SystemReference, config.isCore
  .then (pluginConfig) ->
    # not really using plugin.models..
    return pluginConfig unless pluginConfig.plugin?.models
    for name, model in pluginConfig.plugin.models
      SystemReference.registerModel name, model
  .then (pluginConfig) ->
    return pluginConfig unless pluginConfig.plugin?.init
    Promise.promise (resolve, reject) ->
      pluginConfig.plugin.init (err) ->
        return reject err if err
        resolve pluginConfig
