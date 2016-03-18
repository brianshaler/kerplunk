_ = require 'lodash'
Promise = require 'when'

setupByConfig = require './setupByConfig'
registerComponents = require './registerComponents'
addModelsToConfigs = require './addModelsToConfigs'
populateDependencyPromises = require './populateDependencyPromises'

loadAllConfigs = require './configs/loadAllConfigs'
sortPlugins = require './configs/sortPlugins'

PluginSchema = require '../models/Plugin'
JobSchema = require '../models/Job'

# Database = require './database'

filterLoadable = (allConfigs) ->
  allConfigs = _.filter allConfigs, (config) ->
    config.isCore == true or config.model?.enabled == true
  sorted = sortPlugins [], allConfigs
  allConfigs = _.filter sorted, (config) ->
    return true if config.isCore == true
    return false if config.canBeLoaded == false
    true

module.exports = (System, activePlugins, waitForComponents = false) ->
  loadAllConfigs System
  .then (configs) ->
    allConfigs = configs[0].concat configs[1]
    dbConfig = _.find allConfigs, (cfg) ->
      cfg.name == 'kerplunk-database'
    # return Promise() if activePlugins[dbConfig.name]
    setupByConfig System, dbConfig
    .then (config) ->
      activePlugins[config.name] = config
      mongoose = System.getMongoose 'kerplunk'
      PluginSchema mongoose
      JobSchema mongoose
      System.checkSetup()
    .then -> allConfigs
  .then addModelsToConfigs System
  .then filterLoadable
  .then populateDependencyPromises
  .then (allConfigs) ->
    Promise.all _.map allConfigs, (config) ->
      if activePlugins[config.name]
        config.loadStatus = true
        config.initDeferred.resolve 'already loaded'
        # console.log config.name, 'is already active'
        return config.initPromise
      # console.log 'load eventually:', config.name, config.deps.length
      startTime = null
      Promise.all _.pluck config.deps, 'initPromise'
      .then (stuff) ->
        startTime = Date.now()
        # console.log '+ deps loaded for:', config.name
        setupByConfig System, config
      .then ->
        activePlugins[config.name] = config
        # console.log '> initialized:', config.name, Math.round((Date.now()-startTime) / 100) / 10 + 's'
        config.loadStatus = true
        config.initDeferred.resolve config.name + '.loaded'
      .catch (err) ->
        config.initDeferred.reject err

      config.initPromise
      .catch (err) ->
        console.log 'oh well', err?.stack ? err
  .then ->
    register = ->
      Promise.all _.map activePlugins, (plugin) ->
        # console.log 'registerComponents', plugin.name
        registerComponents System, plugin
      .then ->
        System.do 'componentsRegistered', {}
      .catch (err) ->
        console.log 'issues with components registering', err
    if waitForComponents == true
      register()
    else
      setTimeout register, 10
      true
