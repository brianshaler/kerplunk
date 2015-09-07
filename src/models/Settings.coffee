Promise = require 'when'

###
# Settings schema
###

module.exports = (mongoose) ->
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId

  SettingsSchema = new Schema
    option:
      type: String
    value: {}

  SettingsSchema.pre 'save', (next) ->
    @markModified 'value'
    next()

  SettingsSchema.statics.findOrCreate = (option, next) ->
    Settings = mongoose.model 'Settings'
    mpromise = Settings
    .where
      option: option
    .findOne()

    promise = Promise(mpromise).then (s) ->
      return s if s
      console.log "Creating Settings for #{option}"
      s = new Settings
        option: option
        value: {}
      Promise s.save()
      .then -> s
    if typeof next is 'function'
      return promise.done (s) ->
        next null, s
      , next
    promise

  mongoose.model 'Settings', SettingsSchema
