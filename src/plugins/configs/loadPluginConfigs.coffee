_ = require 'lodash'
Promise = require 'when'

loadPluginConfig = require './loadPluginConfig'

module.exports = (pluginNames) ->
  Promise.settle _.map pluginNames, loadPluginConfig
  .then (descriptors) ->
    failed = _.filter (item) -> item.state != 'fulfilled'
    unless failed?.length == 0
      console.error 'failed', failed
    _ descriptors
      .filter (item) -> item.state == 'fulfilled'
      .pluck 'value'
      .value()
