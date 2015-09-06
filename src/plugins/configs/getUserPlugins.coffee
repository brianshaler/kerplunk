path = require 'path'

_ = require 'lodash'
modulesByKeyword = require 'modules-by-keyword'

module.exports = (System) ->
  throw new Error 'no base dir provided?' unless System.baseDir
  modulesByKeyword 'kerplunk-plugin', path.join System.baseDir, 'node_modules'
  .then (allPluginNames) ->
    _.difference allPluginNames, System.pluginData().core
  .catch (err) ->
    console.log 'modules-by-keyword failed', err
