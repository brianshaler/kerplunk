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

  SettingsSchema.pre "save", (next) ->
    @markModified "value"
    next()

  SettingsSchema.statics.findOrCreate = (option, next) ->
    Settings = mongoose.model "Settings"
    Settings.findOne {option: option}, (err, s) =>
      return next err if err
      if s
        s.value = {} unless s.value?
        next null, s
      else
        console.log "Creating Settings for #{option}"
        s = new Settings
          option: option
          value: {}
        s.save (err) ->
          next err, s

  mongoose.model "Settings", SettingsSchema
