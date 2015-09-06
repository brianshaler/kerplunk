_ = require 'lodash'
Promise = require 'when'
Promise.sequence = require 'when/sequence'

loadAllConfigs = require './configs/loadAllConfigs'
initPlugin = require './initPlugin'
setupByConfig = require './setupByConfig'
registerComponents = require './registerComponents'
addModelsToConfigs = require './addModelsToConfigs'
sortPlugins = require './configs/sortPlugins'

PluginSchema = require '../models/Plugin'

# Database = require './database'

sequence = (list, task) ->
  Promise.sequence _.map list, (obj) ->
    -> task obj

module.exports = (System, activePlugins) ->
  # console.log 'init plugins'
  _setupByConfig = _.curry(setupByConfig) System
  _sequentiallyInit = _.partialRight sequence, initPlugin
  Plugin = null

  loadAllConfigs System
  .then (allConfigs) ->
    #console.log 'POST-SORT', _.pluck allConfigs, 'name'
    [coreConfigs, userConfigs] = allConfigs

    sequence coreConfigs, (config) ->
      return Promise(activePlugins[config.name]) if activePlugins[config.name]?
      _setupByConfig config
      .then (config) ->
        #console.log 'adding plugin to active', config.name
        activePlugins[config.name] = config
        config
    .then _sequentiallyInit
    .then ->
      # get mongoose reference after kerplunk-database has been set up
      mongoose = System.getMongoose 'kerplunk'
      Plugin = PluginSchema mongoose
      System.checkSetup()
      .then ->
        userConfigs
    .then addModelsToConfigs System
    .then (configsWithPlugins) ->
      # model exists and enabled was set
      enabled = _.filter configsWithPlugins, (config) ->
        config.model?.enabled == true and config.canBeLoaded != false
      names = _.pluck enabled, 'name'
      # filter out plugins with missing deps
      sorted = sortPlugins [], enabled
      _.filter sorted, (config) ->
        return false if config.canBeLoaded == false
        satisfied = true
        if config.kerplunk?.dependencies?.length > 0
          for dep in config.kerplunk.dependencies
            continue if activePlugins[dep]? # core
            continue if -1 < names.indexOf dep
            satisfied = false
        satisfied
    .then (filteredConfigs) ->
      sequence filteredConfigs, (config) ->
        _setupByConfig config
        .then (config) ->
          #console.log 'adding plugin to active', config.name
          activePlugins[config.name] = config
          config
    .then _sequentiallyInit
    .then -> _.flatten allConfigs
  .then (allConfigs) ->
    # console.log 'registerComponents'
    #Promise.map _.toArray(activePlugins), _.curry(registerComponents) System
    Promise.all _.map activePlugins, (plugin) ->
      # console.log 'registerComponents', plugin.name
      registerComponents System, plugin
    .then ->
      System.do 'componentsRegistered', {}
    .catch (err) ->
      console.log 'issues with components registering', err
    # pass configs through right away
    # let components get registered asynchronously
    allConfigs
  .then (allConfigs) ->
    # console.log 'done!', allConfigs.length, _.pluck allConfigs, 'name'
    # console.log 'done!', Object.keys(activePlugins).length, Object.keys(activePlugins)
    allConfigs
  .catch (err) ->
    console.log 'plugins.init failed'
    console.log err?.stack ? err
