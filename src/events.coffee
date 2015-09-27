_ = require 'lodash'
Promise = require 'when'

dotStringToObj = (root, key) ->
  keys = key.split '.'
  ref = root
  while keys.length > 0 and ref?
    _key = keys.shift()
    ref = ref[_key]
  ref

module.exports = (System) ->
  initEvents = ->
    init:
      do: ->
        # console.log 'Initialization complete!'
        Promise.resolve()
    componentsRegistered:
      do: ->
        # console.log 'do:componentsRegistered!'
        Promise.resolve()

  events = initEvents()

  processPlugins: (plugins) ->
    events = initEvents()

    for pluginName, plugin of plugins
      if plugin.plugin.globals?.events
        console.log 'WARN', pluginName, 'is using globals.events'
        _.merge events, plugin.plugin.globals.events
        events[pluginName] = plugin.plugin.globals.events
      if plugin.plugin.events
        _.merge events, plugin.plugin.events
        events[pluginName] = plugin.plugin.events

  do: (eventName, data) ->
    fullName = "#{eventName}.do"
    doer = dotStringToObj events, fullName
    # console.log 'events', System.getGlobal 'events'
    unless typeof doer is 'function'
      return Promise.reject new Error "no doer #{fullName}"

    pres = []
    posts = []
    for pluginName, pluginEvents of events
      prefix = "#{pluginName}.#{eventName}."
      pre = dotStringToObj events, "#{prefix}pre"
      pres.push pre if pre
      post = dotStringToObj events, "#{prefix}post"
      posts.push post if post

    pres = _.sortBy pres, (pre) ->
      if pre.precedence?
        pre.precedence
      else
        0
    posts = _.sortBy posts, (post) ->
      if post.precedence?
        post.precedence
      else
        0

    promise = Promise.resolve data
    # console.log "#{eventName} - pres: #{pres.length}; posts: #{posts.length}"
    for fn in pres
      do (fn) ->
        promise = promise.then (_data) ->
          Promise fn _data
          .catch (err) -> _data
          .then -> data
    promise = promise.then doer
    for fn in posts
      do (fn) ->
        promise = promise.then (_data) ->
          Promise fn _data
          .catch (err) -> _data
          .then -> data
    promise
