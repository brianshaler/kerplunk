###
# Base application
###

fs = require 'fs'
path = require 'path'

KerplunkSystem = require './system'

unless process.env.BASE_DIR
  process.env.BASE_DIR = path.resolve __dirname, '..'

credentials = null
keyFile = path.resolve process.env.BASE_DIR, 'cache/server.key'
certFile = path.resolve process.env.BASE_DIR, 'cache/server.crt'

if fs.existsSync certFile
  privateKey  = fs.readFileSync keyFile, 'utf8'
  certificate = fs.readFileSync certFile, 'utf8'
  credentials =
    key: privateKey
    cert: certificate
else
  console.log 'did not see ssl cert', certFile

System = KerplunkSystem
  baseDir: process.env.BASE_DIR
  credentials: credentials

startTime = Date.now()
System.init()
.then ->
  console.log 'Init complete!', (Date.now() - startTime) / 1000
