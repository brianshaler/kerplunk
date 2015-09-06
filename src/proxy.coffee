SystemAPI = require './api'

addMethod = (obj, System, pluginName, method, fn) ->
  obj[method] = ->
    args = [pluginName]
    for arg in arguments
      args.push arg
    #console.log 'called', method, 'with', args
    fn.apply System, args

module.exports = (System) ->
  (pluginName, isCore) ->
    api = {}
    API = SystemAPI System

    for method, fn of API.user
      addMethod api, System, pluginName, method, fn

    if isCore
      for method, fn of API.core
        addMethod api, System, pluginName, method, fn

    api.baseDir = System.baseDir

    api
