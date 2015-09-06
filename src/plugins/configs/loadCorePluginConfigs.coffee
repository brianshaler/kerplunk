loadPluginConfigs = require './loadPluginConfigs'

module.exports = (System) ->
  loadPluginConfigs System.pluginData().core
  .then (configs) ->
    for config in configs
      config.isCore = true
      config.autoEnable = true
    configs
