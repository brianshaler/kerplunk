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
      AppSettings.getSettingsModel()
      .findOrCreate 'kerplunk-admin'
      .then (settings) ->
        AppSettings.settings = settings?.value ? {}
        AppSettings.settings.isSetup = settings?.value?.setupStep >= 1
        AppSettings.settings

    getPluginSettings: (pluginName) ->
      AppSettings.getSettingsModel()
      .findOrCreate pluginName
      .then (settings) ->
        settings.value ? {}

    updatePluginSettings: (pluginName, newVal) ->
      if newVal?.$set
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
        Promise.promise (resolve, reject) ->
          AppSettings.getSettingsModel()
          .findOrCreate pluginName, (err, settings) ->
            return reject err if err
            settings.value = newVal
            settings.markModified 'value'
            resolve settings.save().then -> settings.value
