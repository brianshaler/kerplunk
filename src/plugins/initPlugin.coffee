Promise = require 'when'

module.exports = (obj) ->
  unless obj.plugin?.init
    #console.log 'no init on this plugin?', obj
    return obj
  Promise.promise (resolve, reject) ->
    obj.plugin.init (err) ->
      return reject err if err
      resolve obj
