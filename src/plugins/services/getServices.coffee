path = require 'path'

_ = require 'lodash'
Promise = require 'when'

setupService = require './setupService'

module.exports = (System, config) ->
  #console.log 'getService', config.kerplunk
  return Promise.resolve [] unless config.kerplunk?.services
  return Promise.resolve [] unless 0 < Object.keys(config.kerplunk.services).length
  #console.log 'SERVICE!', config.name

  serviceArray = _.map config.kerplunk.services, (serviceConfig, serviceName) ->
    System: System
    pluginName: config.name
    serviceName: serviceName
    serviceConfig: serviceConfig

  Promise.map serviceArray, setupService
