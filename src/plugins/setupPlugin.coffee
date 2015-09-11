fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'

Promise = require 'when'

createLink = (targetPath, linkPath) ->
  fs.exists linkPath, (linkExists) ->
    return if linkExists
    fs.exists targetPath, (targetExists) ->
      if targetExists
        linkcmd = "ln -s #{targetPath}/ #{linkPath}"
        console.log '$', linkcmd
        exec linkcmd #, (err, data) -> throw err if err


module.exports = (pluginConfig, System) ->
  #console.log 'setupPlugin', pluginConfig.name, pluginConfig.isCore
  pluginConfig.plugin = false
  mainFile = pluginConfig.main.replace /^[\.\/]*/, ''
  baseDir = System.baseDir ? process.env.BASE_DIR ? __dirname
  pluginRoot = path.join baseDir, 'node_modules', pluginConfig.name
  fullPath = path.join pluginRoot, mainFile
  pluginAssetPath = path.join pluginRoot, 'public'
  publicAssetPath = path.join baseDir, 'public', 'plugins', pluginConfig.name

  Promise.promise (resolve, reject) ->
    createLink pluginAssetPath, publicAssetPath
    # console.log 'setup!', pluginConfig.name, pluginConfig.isCore
    pluginModule = require fullPath
    pluginConfig.plugin = pluginModule System
    pluginConfig.path = pluginRoot
    resolve pluginConfig
