_ = require 'lodash'
Promise = require 'when'

module.exports = (allConfigs) ->
  coreNames = _ allConfigs
  .filter (c) -> c.isCore == true
  .pluck 'name'
  .value()

  _.map allConfigs, (config) ->
    config.initDeferred = Promise.defer()
    config.initPromise = config.initDeferred.promise
    config.loadStatus = false
    if config.name == 'kerplunk-database'
      config.deps = []
      config.loadStatus = true
      config.initDeferred.resolve()
      return config
    if config.name == 'kerplunk-server'
      config.deps = []
      return config
    # all other core plugins must wait for kerplunk-server
    depNames = if config.isCore == true
      ['kerplunk-server']
    else
      coreNames
    depNames = depNames.concat config.kerplunk?.dependencies ? []
    config.deps = _.map depNames, (name) ->
      dep = _.find allConfigs, (c) ->
        c.name == name
      return dep if dep
      initPromise: Promise.reject new Error "Missing dependency: #{name}"
    config
