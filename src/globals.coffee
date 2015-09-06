_ = require 'lodash'

module.exports = (System) ->
  globals =
    public: {}

  processPlugins: (plugins) ->
    console.log 'loading all globals from plugins without checking permissions...'
    globals =
      public: {}
    routes = {}
    for pluginName, plugin of plugins
      if plugin.plugin.globals
        _.merge globals, plugin.plugin.globals
      pluginRoutes = null
      if plugin.plugin.routes?.admin or plugin.plugin.routes?.public
        pluginRoutes = _.extend {}, (plugin.plugin.routes.admin ? {}), (plugin.plugin.routes.public ? {})
      if pluginRoutes and plugin.plugin.handlers
        for route, handlerKey of pluginRoutes
          if typeof plugin.plugin.handlers[handlerKey] is 'string'
            routes[route] = "#{plugin.name}:#{handlerKey}"
    globals.public.routes = routes
    globals

  set: (key, val) ->
    val = _.clone val, true
    keys = key.split '.'
    ref = globals

    while keys.length > 1
      _key = keys.shift()
      ref[_key] = {} unless ref[_key]?
      ref = ref[_key]

    if val instanceof Array
      ref[keys[0]] = val
    else if typeof val is 'object'
      ref[keys[0]] = {} unless ref[keys[0]]?
      _.merge ref[keys[0]], val
    else
      ref[keys[0]] = val

  get: (key) ->
    keys = key.split '.'
    ref = globals
    while keys.length > 0 and ref?
      _key = keys.shift()
      ref = ref[_key]
    ref

  getGlobals: -> globals
