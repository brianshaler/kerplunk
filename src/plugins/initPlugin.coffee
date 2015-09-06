Promise = require 'when'

module.exports = (obj) ->
  unless obj.plugin?.init
    #console.log 'no init on this plugin?', obj
    return obj
  deferred = Promise.defer()
  obj.plugin.init (err) ->
    return deferred.reject err if err
    deferred.resolve obj
  deferred.promise
