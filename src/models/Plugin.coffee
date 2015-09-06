###
# Plugin schema
###

module.exports = (mongoose) ->
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId

  PluginSchema = new Schema
    name:
      type: String
      required: true
      index:
        unique: true
    displayName:
      type: String
    enabled:
      type: Boolean
      default: false
    updatedAt:
      type: Date
      default: -> new Date 0
    createdAt:
      type: Date
      default: Date.now

  PluginSchema.pre 'save', (next) ->
    @updatedAt = new Date()
    next()

  mongoose.model 'Plugin', PluginSchema
