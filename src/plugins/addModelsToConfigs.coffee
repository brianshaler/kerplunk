_ = require 'lodash'
Promise = require 'when'

module.exports = (System) ->
  Plugin = null

  getExisting = (names) ->
    deferred = Promise.defer()
    Plugin.find
      name:
        '$in': names
    , (err, plugins) ->
      return deferred.reject err if err
      plugins = [] unless plugins?.length > 0
      deferred.resolve plugins
    deferred.promise

  (configs) ->
    mongoose = System.getMongoose 'kerplunk'
    Plugin = mongoose.model 'Plugin'
    getExisting _.pluck configs, 'name'
    .then (existing) ->
      Promise.all _.map configs, (config) ->
        model = _.find existing, (m) ->
          m.name == config.name
        if model
          config.model = model
          return config
        model = new Plugin
          name: config.name
          enabled: config.autoEnable == true or config.isCore == true
        config.model = model
        deferred = Promise.defer()
        model.save (err) ->
          return deferred.reject err if err
          deferred.resolve config
        deferred.promise
