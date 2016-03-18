module.exports = (System) ->
  components = {}

  reset: ->
    components = {}

  keys: ->
    Object.keys components

  set: (pathName, component) ->
    components[pathName] = component

  get: (pathName) ->
    component = components[pathName]
    if typeof component is 'string'
      try
        component = components[pathName] = require component
      catch err
        console.log 'problem trying to require', component
        console.log err?.stack ? err
        return
    # TODO
    # check: !component or typeof component is 'string'
    component
