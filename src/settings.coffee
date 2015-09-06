Promise = require 'when'

SettingsSchema = require './models/Settings'

module.exports = (System) ->
  AppSettings =
    settings: {}
    SettingsModel: null

    getSettingsModel: ->
      return AppSettings.SettingsModel if AppSettings.SettingsModel
      mongoose = System.getMongoose 'kerplunk'
      AppSettings.SettingsModel = mongoose.model 'Settings', SettingsSchema mongoose

    getSettings: ->
      Promise.promise (resolve, reject) ->
        AppSettings.getSettingsModel()
        .findOrCreate 'kerplunk-admin', (err, settings) ->
          return reject err if err
          AppSettings.settings = settings?.value ? {}
          AppSettings.settings.isSetup = settings?.value?.setupStep >= 1
          resolve AppSettings.settings

    getPluginSettings: (pluginName) ->
      Promise.promise (resolve, reject) ->
        # console.log 'getSettings', pluginName, typeof callback
        AppSettings.getSettingsModel()
        .findOrCreate pluginName, (err, settings) ->
          return reject err if err
          resolve settings.value ? {}

    updatePluginSettings: (pluginName, newVal) ->
      Promise.promise (resolve, reject) ->
        AppSettings.getSettingsModel()
        .findOrCreate pluginName, (err, settings) ->
          return reject err if err
          settings.value = newVal
          settings.markModified 'value'
          resolve settings.save().then -> settings.value
