fs = require 'fs'
path = require 'path'

_ = require 'lodash'
Promise = require 'when'

init = require './init'
loadAllConfigs = require './configs/loadAllConfigs'

module.exports = (System) ->

  activePlugins = {}
  corePluginsStarted = false
  jobTimeout = null
  jobs = []

  Plugins =
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

    init: (waitForComponents = false) ->
      init System, activePlugins, waitForComponents
      .then (configs) -> null

    runPlugin: (pluginName, plugin) ->
      plugin.start() if plugin.start
      return unless plugin.jobs
      mongoose = System.getMongoose 'kerplunk'
      Job = mongoose.model 'Job'
      Promise.all _.map plugin.jobs, (job, jobName) ->
        Job.getOrCreate pluginName, jobName
        .then (jobModel) ->
          pluginName: pluginName
          jobName: jobName
          model: jobModel
          frequency: job.frequency * 1000
          task: job.task
          running: false
      .then (pluginJobs) ->
        return unless pluginJobs?.length > 0
        for job in pluginJobs
          jobs.push job

    run: ->
      jobs = []
      Promise.all _.map activePlugins, (plugin, name) ->
        return if corePluginsStarted and plugin.isCore and plugin.plugin.noRestart
        Plugins.runPlugin name, plugin.plugin
      .then ->
        corePluginsStarted = true
      .then Plugins.runJobs

    runJobs: ->
      jobFrequency = 5000
      clearTimeout jobTimeout
      currentDate = new Date()
      currentTime = currentDate.getTime()
      for job in jobs
        continue unless job?.model?.nextRun < currentDate
        unless job.frequency > jobFrequency
          job.frequency = jobFrequency
        continue unless typeof job.task is 'function'
        continue unless job.running == false
        do (job) ->
          name = "#{job.pluginName}:#{job.jobName}"
          job.model.nextRun = new Date currentTime + job.frequency
          canRun = true
          Promise job.model.save()
          .catch (err) ->
            console.log 'JOB save error', err.stack ? err
            canRun = false
          .then ->
            return unless canRun == true
            console.log 'JOB: running', name
            job.running = true
            Promise job.task()
            .catch (err) ->
              console.log 'JOB run error', name
              message = [err?.message ? err]
              if err?.stack
                helpfulLines = _.filter err.stack.split('\n'), (line) ->
                  return false unless /kerplunk-plugins/.test line
                  return false if /node_modules/.test line
                if helpfulLines.length > 0
                  message = message.concat helpfulLines.slice(0, 10)
                else
                  message.push err.stack
              console.log message.join '\n'
          .then ->
            console.log 'JOB: finished', name
            job.running = false
          .catch (err) ->
            console.log 'JOB internal error', name, err?.stack ? err
      jobTimeout = setTimeout ->
        Plugins.runJobs()
      , jobFrequency

    stop: ->
      clearTimeout jobTimeout
      jobs = []
      Promise.promise (resolve, reject) ->
        for name, plugin of activePlugins
          continue if plugin.isCore
          plugin.plugin.kill?()
        for name, plugin of activePlugins
          continue if plugin.isCore == true and plugin.plugin.noRestart == true
          delete activePlugins[name]
        console.log 'active after STOP:', Object.keys activePlugins
        resolve()
