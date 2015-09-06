fs = require 'fs'
path = require 'path'

_ = require 'lodash'

kerplunkObj =
  permissions: {}
  services: {}
  dependencies: []

module.exports = (pluginName) ->
  unless process.env.BASE_DIR
    console.log 'WARN: process.env.BASE_DIR not set'
  baseDir = path.join (process.env.BASE_DIR ? __dirname), 'node_modules'
  pluginPath = path.join baseDir, pluginName
  pkg = path.join pluginPath, 'package.json'
  fileContents = fs.readFileSync pkg
    .toString()
  config = JSON.parse fileContents
  config.name = config.name ? pluginName
  config.displayName = config.displayName ? pluginName
  config.description = config.description ? ''
  config.dir = pluginName
  config.path = pluginPath
  config.main = config.main ? './index'
  config.kerplunk = _.merge {}, kerplunkObj, (config.kerplunk ? {})
  config.autoEnable = false
  config.isCore = false
  config
