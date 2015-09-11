_ = require 'lodash'
Promise = require 'when'

SettingsSchema = require './models/Settings'

module.exports = (System) ->
  cache = {}
  AppSettings =
    settings: {}
    SettingsModel: null

    getSettingsModel: ->
      return AppSettings.SettingsModel if AppSettings.SettingsModel
      mongoose = System.getMongoose 'kerplunk'
      AppSettings.SettingsModel = mongoose.model 'Settings', SettingsSchema mongoose

    getSettings: ->
      AppSettings.getPluginSettings 'kerplunk-admin'
      .then (appSettings) ->
        AppSettings.settings = appSettings
        AppSettings.settings.isSetup = appSettings.setupStep >= 1
        AppSettings.settings

    getPluginSettings: (pluginName) ->
      if cache[pluginName]
        return Promise.resolve cache[pluginName]
      # console.log "getPluginSettings: #{pluginName}"
      mpromise = AppSettings.getSettingsModel()
      .where {}
      .find()
      .then (settings) ->
        return {} unless settings?.length > 0
        cache[pluginName] = {}
        for setting in settings
          cache[setting.option] = setting.value
        cache[pluginName]
      Promise mpromise

    updatePluginSettings: (pluginName, newVal) ->
      # console.log "updatePluginSettings: #{pluginName}", newVal
      if newVal?.$set
        if cache[pluginName]
          _.merge cache[pluginName], newVal.$set
        where =
          option: pluginName
        updateVal =
          $set: {}
        for k, v of newVal.$set
          updateVal.$set["value.#{k}"] = v
        mpromise = AppSettings.getSettingsModel()
        .update where, updateVal
        Promise mpromise
      else
        cache[pluginName] = newVal
        Promise.promise (resolve, reject) ->
          AppSettings.getSettingsModel()
          .findOrCreate pluginName, (err, settings) ->
            return reject err if err
            settings.value = newVal
            settings.markModified 'value'
            resolve settings.save().then -> settings.value
