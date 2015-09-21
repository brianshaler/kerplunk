Promise = require 'when'

###
# Job schema
###

module.exports = (mongoose) ->
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId

  JobSchema = new Schema
    guid:
      type: String
      required: true
      index:
        unique: true
    pluginName:
      type: String
      required: true
      index: true
    jobName:
      type: String
      required: true
      index: true
    nextRun:
      type: Date
      default: Date.now
    createdAt:
      type: Date
      default: Date.now

  JobSchema.statics.getOrCreate = (pluginName, jobName) ->
    Job = mongoose.model 'Job'
    guid = "#{pluginName}:#{jobName}"
    mpromise = Job
    .where
      guid: guid
    .findOne()
    Promise(mpromise)
    .then (job) ->
      return job if job
      console.log 'create new job', pluginName, jobName
      job = new Job
        guid: guid
        pluginName: pluginName
        jobName: jobName
        nextRun: new Date()
      job.save()
      .then -> job

  mongoose.model 'Job', JobSchema
