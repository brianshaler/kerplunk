_ = require 'lodash'
Promise = require 'when'

loadCorePluginConfigs = require './loadCorePluginConfigs'
loadUserPluginConfigs = require './loadUserPluginConfigs'
sortPlugins = require './sortPlugins'

module.exports = (System) ->
  Promise.all [
    loadCorePluginConfigs System
    loadUserPluginConfigs System
  ]
  .then (coreAndUserConfigs) ->
    [coreConfigs, userConfigs] = coreAndUserConfigs
    allConfigs = sortPlugins coreConfigs, userConfigs
    [
      _.filter allConfigs, (c) -> c.isCore == true
      _.filter allConfigs, (c) -> c.isCore != true
    ]
