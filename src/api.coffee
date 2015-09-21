_ = require 'lodash'

module.exports = (System) ->
  user:
    getMongoose: (pluginName, dbName = 'public') ->
      console.log 'WARN', pluginName, 'is calling getMongoose' if dbName == 'public'
      return System.getMongoose dbName if dbName == 'public' or pluginName == dbName
      if System.checkPermissions pluginName, 'kerplunk-database', 'db', dbName
        System.getMongoose dbName
      else
        console.log "permission denied: #{pluginName}=>kerplunk-database.db.#{dbName}"

    getService: (pluginName, serviceName) ->
      System.services?[pluginName]?[serviceName]

    setService: (pluginName, serviceName, ip, ports) ->
      obj = {}
      obj[pluginName] = {}
      obj[pluginName][serviceName] =
        ip: ip
        ports: ports
      System.services = {} unless System.services
      _.merge System.services, obj

    getMethod: (pluginName, requestedPlugin, methodName) ->
      plugin = null
      if System.checkPermissions pluginName, requestedPlugin, 'methods', methodName
        plugin = System.getPlugin requestedPlugin
      else
        console.log "DENIED: #{pluginName}=>#{requestedPlugin}.methods.#{methodName}"
      plugin?.methods?[methodName]

    getModel: (pluginName, requestedPlugin, modelName) ->
      if -1 != requestedPlugin.indexOf ':'
        [requestedPlugin, modelName] = requestedPlugin.split ':'
      unless modelName?
        modelName = requestedPlugin
        requestedPlugin = System.findModelOwner modelName
        # console.log pluginName, 'had to guess model owner for', modelName, 'and found', requestedPlugin
      if System.checkPermissions pluginName, requestedPlugin, 'models', modelName
        return System.getModel requestedPlugin, modelName
      console.log "DENIED: #{pluginName}=>#{requestedPlugin}.models.#{modelName}"

    getGlobal: (pluginName, key) ->
      if System.requestGlobalAccess pluginName, key
        return System.getGlobal key
      console.log "DENIED: #{pluginName}=>globals.#{key}"

    getRoutes: (pluginName) ->
      System.getRoutes()

    getComponent: (pluginName, pathname) ->
      component = System.getComponent pathname
      unless component
        return console.log 'component not found', pathname
      component

    registerModel: (pluginName, modelName, model) ->
      System.registerModel pluginName, modelName, model

    registerComponent: (pluginName, componentName, component) ->
      System.registerComponent pluginName, componentName, component

    getComponentPaths: ->
      System.getComponentPaths()

    getSettings: (pluginName, callback) ->
      System.getSettings pluginName, callback

    getSettingsByName: (pluginName, targetName, callback) ->
      # if a wants settings for b, should require permissions
      return System.getSettings pluginName, callback if pluginName == targetName
      if System.checkPermissions pluginName, targetName, 'settings'
        return System.getSettings targetName, callback
      unless typeof callback is 'function'
        callback = Promise.reject
      callback new Error 'permission denied'

    updateSettingsByName: (pluginName, targetName, settings, callback) ->
      # if a wants settings for b, should require permissions
      return System.updateSettings pluginName, settings, callback if pluginName == targetName
      if System.checkPermissions pluginName, targetName, 'settings'
        return System.updateSettings targetName, settings, callback
      unless typeof callback is 'function'
        callback = Promise.reject
      callback new Error 'permission denied'

    updateSettings: (pluginName, newVal, callback) ->
      System.updateSettings pluginName, newVal, callback

    getSocket: (pluginName, socketName) ->
      System.getSocket socketName

    getMe: (pluginName) ->
      System.getMe()

    resetGlobals: (pluginName) ->
      System.resetGlobals()

    reset: (pluginName) ->
      System.reset()

    do: (pluginName, eventName, data) ->
      System.do eventName, data

  core:
    setGlobal: (pluginName, key, val) ->
      System.setGlobal key, val

    getGlobals: -> System.getGlobals()

    getAvailablePlugins: (pluginName, next) ->
      System.getAvailablePlugins next

    getCredentials: ->
      System.credentials

    getPlugins: ->
      System.getPlugins()

    getPlugin: (pluginName, requestedPlugin) ->
      System.getPlugin requestedPlugin

    isSetup: -> System.isSetup()

    installPlugin: (pluginName, requestedPlugin) ->
      System.installPlugin requestedPlugin
