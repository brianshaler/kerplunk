_ = require 'lodash'

getSatisfied = (existingNames, pending) ->
  _.reduce pending, (memo, plugin) ->
    unless plugin.kerplunk.dependencies?.length > 0
      memo[0].push plugin
      return memo
    for dep in plugin.kerplunk.dependencies
      if -1 == existingNames.indexOf dep
        memo[1].push plugin
        return memo
    memo[0].push plugin
    return memo
  , [[], []]

sortByDep = (plugins, sorted = []) ->
  [satisfied, unsatisfied] = getSatisfied _.pluck(sorted, 'name'), plugins
  for plugin in satisfied
    sorted.push plugin

  if unsatisfied.length > 0 and unsatisfied.length >= plugins.length
    console.log 'WARN: Dependencies not met:', _.pluck unsatisfied, 'name'
    # console.log plugins, satisfied, unsatisfied
    # throw new Error 'shit just went down'
    for plugin in unsatisfied
      plugin.canBeLoaded = false
      sorted.push plugin
    return sorted

  return sorted if unsatisfied.length == 0
  # um.. should probably throw or something
  return sorted if satisfied.length == 0
  sortByDep unsatisfied, sorted

module.exports = (corePlugins, userPlugins) ->
  # sort core first, then add sorted user plugins
  tmp = sortByDep userPlugins, sortByDep corePlugins
  # console.log 'sorted', _.pluck tmp, 'name'
  tmp
