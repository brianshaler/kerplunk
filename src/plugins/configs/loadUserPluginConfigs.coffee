_ = require 'lodash'

getUserPlugins = require './getUserPlugins'
loadPluginConfigs = require './loadPluginConfigs'

module.exports = (System) ->
  getUserPlugins System
  .then loadPluginConfigs
  .then (configs) ->
    for pluginName in System.pluginData().auto
      config = _.find configs, (c) ->
        c.name == pluginName
      if config
        config.autoEnable = true
    configs
