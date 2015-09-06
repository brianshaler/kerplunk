fs = require 'fs'
path = require 'path'

Promise = require 'when'
readdir = require 'recursive-readdir'

getFiles = (componentsPath) ->
  deferred = Promise.defer()
  fs.exists componentsPath, (exists) ->
    return deferred.resolve [] unless exists
    readdir componentsPath, (err, files) ->
      return deferred.reject err if err
      deferred.resolve files
  deferred.promise

module.exports = (System, config) ->
  componentsPath = path.join config.path, 'lib', 'components'
  getFiles componentsPath
  .then (files) ->
    for fullPath in files
      ext = path.extname fullPath
      relativePath = fullPath.substring componentsPath.length + 1
      relativePath = relativePath.substring 0, relativePath.length - ext.length
      #console.log 'relativePath', relativePath
      componentPath = "#{config.name}:#{relativePath}"
      # console.log 'register', componentPath
      System.registerComponent config.name, componentPath, fullPath
  .then -> config
