fs = require 'fs'
path = require 'path'

_ = require 'lodash'
modulesByKeyword = require 'modules-by-keyword'
Promise = require 'when'

init = require './init'
loadAllConfigs = require './configs/loadAllConfigs'

module.exports = (System) ->

  activePlugins = {}
  intervals = []
  corePluginsStarted = false

  PluginManager =
    get: (name) ->
      #console.log 'plugins.get', name, Object.keys activePlugins
      p = activePlugins[name]?.plugin
      unless p?
        console.log "plugin #{name} not found?", Object.keys activePlugins
      p

    getContainer: (name) ->
      activePlugins[name]

    getAll: -> activePlugins

    getAvailablePlugins: (next) ->
      loadAllConfigs System
      .done (allConfigs) ->
        [coreConfigs, userConfigs] = allConfigs
        for config in userConfigs
          config.enabled = !!activePlugins[config.name] and config.canBeLoaded != false
        next null, userConfigs, coreConfigs
      , (err) ->
        next err

    init: ->
      init System, activePlugins
      .then (configs) -> null

    runPlugin: (name, plugin) ->
      plugin.start() if plugin.start
      return unless plugin?.crons?.length > 0
      for job in plugin.crons
        if job.frequency >= 1
          do (job) ->
            job.intervalId = setInterval ->
              unless job.running
                try
                  job.running = true
                  job.task ->
                    job.running = false
                catch ex
                  job.running = false
                  console.error 'Cron job failed'
                  console.error ex
            , job.frequency * 1000

    run: ->
      Promise.promise (resolve, reject) ->
        # console.log 'plugins.run()', Object.keys activePlugins
        for name, plugin of activePlugins
          continue if corePluginsStarted and plugin.isCore and plugin.plugin.noRestart
          PluginManager.runPlugin name, plugin.plugin
        corePluginsStarted = true
        resolve()

    stop: ->
      Promise.promise (resolve, reject) ->
        for name, plugin of activePlugins
          continue if plugin.isCore
          for job in (plugin.plugin.crons ? [])
            clearInterval job.intervalId
          plugin.plugin.kill?()
        for name, plugin of activePlugins
          continue if plugin.isCore == true and plugin.plugin.noRestart == true
          delete activePlugins[name]
        console.log 'active after STOP:', Object.keys activePlugins
        resolve()
