path = require 'path'

_ = require 'lodash'
Promise = require 'when'

pluginData = require '../plugins.json'

AppSettings = require './settings'
Plugins = require './plugins'
Components = require './components'
Events = require './events'
Globals = require './globals'
SystemProxy = require './proxy'

module.exports = (params = {}) ->
  isSetup = false
  me = null
  models = {}

  System = _.extend {}, params

  proxy = SystemProxy System
  globals = Globals System
  components = Components System
  events = Events System
  plugins = Plugins System
  appSettings = AppSettings System

  checkSetup = ->
    appSettings.getSettings()
    .then (settings) ->
      settings.isSetup == true

  _.extend System,
    baseDir: path.resolve __dirname, '..'
    pluginData: -> _.clone pluginData, true
    getPlugins: -> plugins.getAll()
    getAvailablePlugins: (next) ->
      plugins.getAvailablePlugins next
    getPluginContainer: (pluginName) ->
      plugins.getContainer pluginName
    getPlugin: (pluginName) ->
      plugins.get pluginName

    do: (eventName, data) ->
      events.do eventName, data

    resetGlobals: ->
      console.log 'System: resetGlobals'
      globals.processPlugins plugins.getAll()
      plugins.get('kerplunk-server').reset()
    setGlobal: (key, val) -> globals.set key, val
    getGlobal: (key) -> globals.get key
    getGlobals: -> globals.getGlobals()
    getRoutes: ->
      routes = _ plugins.getAll()
        .map (plugin) -> plugin?.plugin ? plugin
        .map (plugin) ->
          _.flatten _.map (plugin?.routes ? []), (obj, group) ->
            Object.keys obj
        .flatten()
        .compact()
        .value()

    getProxy: (pluginName, isCore = false) ->
      proxy pluginName, (isCore == true)

    checkSetup: -> checkSetup()

    isSetup: -> appSettings.settings.isSetup

    reset: ->
      models = {}
      components.reset()

      console.log 'System: stop server'
      Promise plugins.get('kerplunk-server').stop()
      .then -> console.log 'System: stop plugins'
      .then plugins.stop
      .then -> console.log 'System: init plugins'
      .then checkSetup
      .then -> console.log 'System: init plugins'
      .then ->
        plugins.init true
      .then -> console.log 'System: process globals and events'
      .then plugins.getAll
      .then (plugins) ->
        globals.processPlugins plugins
        events.processPlugins plugins
      .then -> console.log 'System: reset server'
      .then -> plugins.get('kerplunk-server').reset()
      .then -> console.log 'System: run plugins'
      .then plugins.run
      .then ->
        console.log 'components', components.keys().length
        events.do 'init'

    stop: (next) ->
      plugins.get('kerplunk-server').stop ->
        console.log 'System:: server stopped'
        plugins.stop ->
          console.log 'System:: plugins stopped'
          next() if next

    getModel: (pluginName, modelName) ->
      # console.log 'registerComponent', pluginName, pathname
      #console.log component
      models[pluginName]?[modelName]

    findModelOwner: (modelName) ->
      for pluginName, pluginModels of models
        if pluginModels[modelName]
          return pluginName
      return

    getMongoose: (dbName) ->
      dbPlugin = plugins.get 'kerplunk-database'
      dbPlugin.getMongoose dbName

    getMe: ->
      idPlugin = plugins.get 'kerplunk-identity'
      idPlugin.getMe()

    registerModel: (pluginName, modelName, schema) ->
      # console.log 'registerModel', pluginName, modelName, schema
      dbPlugin = plugins.get 'kerplunk-database'
      mongoose = dbPlugin.getMongoose 'public'
      models[pluginName] = {} unless models[pluginName]
      models[pluginName][modelName] = schema mongoose

    registerComponent: (pluginName, pathName, component) ->
      components.set pathName, component
    getComponent: (pathName) ->
      components.get pathName
    getComponentPaths: ->
      components.keys()

    getSettings: (pluginName, callback) ->
      promise = appSettings.getPluginSettings pluginName
      if typeof callback is 'function'
        promise.done (settings) ->
          callback null, settings
        , callback
      promise

    updateSettings: (pluginName, newVal, callback) ->
      promise = appSettings.updatePluginSettings pluginName, newVal
      if typeof callback is 'function'
        promise.done (settings) ->
          callback null, settings
        , callback
      promise

    getSocket: (socketName) ->
      plugins.get('kerplunk-server').getSocket socketName

    checkPermissions: (pluginName, keys...) ->
      foundInCore = -1 < pluginData.core.indexOf pluginName
      return true if foundInCore
      return true if pluginName == keys[0]
      ref = appSettings.settings.permissions?[pluginName]
      while ref
        return true if ref['*']? and ref['*'] != false
        return true if ref == true
        ref = ref[keys.shift()]
      false

    requestGlobalAccess: (pluginName, key) ->
      return true if (new RegExp("^#{pluginName}\\.?")).test key
      return true if /^public\.?/.test key
      foundInCore = -1 < pluginData.core.indexOf pluginName
      #console.log 'requestGlobalAccess', pluginName, key
      #console.log isCore == true, key == pluginName, appSettings.settings?.permissions?[pluginName]?.globals?[key] == true
      #unless isCore or key == pluginName
      #  console.log appSettings.settings.permissions?[pluginName]?.globals
      return true if foundInCore
      return true if appSettings.settings.permissions?[pluginName]?.globals?[key] == true
      false

    getAppSettings: -> settings

    installPlugin: (pluginName) ->
      Promise.promise (resolve, reject) ->
        console.log 'installing', pluginName
        {spawn} = require 'child_process'
        childProcess = spawn 'npm', [
          'install'
          pluginName
        ]
        childProcess.stdout.pipe process.stdout
        childProcess.stderr.pipe process.stderr
        childProcess
        .on 'close', ->
          console.log 'installed', pluginName
          console.log 'npm install closed'
          resolve()

  # returns only an init function
  init: ->
    #console.log 'init'
    plugins.init()
    .then plugins.getAll
    .then (plugins) ->
      globals.processPlugins plugins
      events.processPlugins plugins
    .then appSettings.getSettings # done during plugins.init...
    .then plugins.run
    .then ->
      events.do 'init'
      true
