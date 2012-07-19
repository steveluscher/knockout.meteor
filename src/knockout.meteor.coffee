###
Knockout Meteor plugin v0.2.4
(c) 2012 Steven Luscher, Ruboss - http://ruboss.com/
License: MIT (http://www.opensource.org/licenses/mit-license.php)

Create Knockout Observables from queries against Meteor Collections.
When the results of those queries change, knockout.meteor.js will
ensure that the Observables are updated.

http://github.com/steveluscher/knockout.meteor
###

class NotImplementedError extends Error
  constructor: (func_name) ->
    @name = 'NotImplementedError'
    @message = "'#{func_name}' function must be implemented by subclass."

#
# These functions are exported as ko.meteor.find and ko.meteor.findOne
#
meteor =
  find: (collection, selector, options = {}, mapping = {}) ->
    (new FindMany(collection, selector, options, mapping)).run()

  findOne: (collection, selector, options = {}, mapping = {}) ->
    (new FindOne(collection, selector, options, mapping)).run()

#
# A Finder accepts a collection, selector, and options hash as arguments,
# and returns a ko.observable (or ko.observableArray) that will get updated
# whenever the data matched by the query changes, or the query parameters
# themselves change.
#
# collection - a Meteor.Collection object, or
#              a Knockout observable that returns one.
# selector - a Mongo selector, a String, or
#            a Knockout observable that returns a Mongo selector or a String.
# options - an Object, or a Knockout observable that returns an Object
#
class AbstractFinder
  constructor: (@collection, @selector, @options = {}, @mapping = {}) ->
    @target = null

    # If an argument to this finder happens to be a Knockout observable,
    # subscribe to it and recreate the query whenever it changes
    ko.computed =>
      ko.utils.unwrapObservable(@collection)
      ko.utils.unwrapObservable(@selector)
      ko.utils.unwrapObservable(@options)
      ko.utils.unwrapObservable(@mapping)
      return
    .extend({throttle: 1}) # Defer, in case more than one argument changes at a time
    .subscribe(@run)       # Run every time changes are detected

  run: () =>
    # Kill the existing query
    @query.destroy() if @query

    # Prepare the query arguments
    collection = ko.utils.unwrapObservable(@collection)
    selector = ko.utils.unwrapObservable(@selector)
    options = ko.utils.unwrapObservable(@options)
    mapping = @processMapping(ko.utils.unwrapObservable(@mapping))

    # Create a MappedQuery (as defined in subclass)
    @query = @createQuery(collection, selector, options, mapping)

    # Run the query
    @query.run()

  processMapping: (raw_mapping) ->
    mapping = _.clone(raw_mapping)
    
    # Extract the view_model property
    view_model = mapping.view_model
    delete mapping.view_model
    
    # If a root level mapping doesn't exist, create it
    mapping[""] = {} unless _.isObject(mapping[""])
    
    # Merge in some mapping defaults
    _.defaults mapping[""],
      # It's important to key collection members by their Mongo _id so that
      # the Knockout Mapping plugin can determine if an object is new or old
      key: (item) -> ko.utils.unwrapObservable(item._id)

    # If we were passed a view_model in the options hash,
    # instruct the Knockout Mapping plugin to instantiate
    # each Meteor record as an instance of that model
    if _.isFunction view_model
      mapping[""].create = (opts) ->
        return ko.observable() unless opts.data
        ko.mapping.fromJS(opts.data, mapping, new view_model(opts.data))
    
    mapping
    
  createQuery: (collection, selector, options, mapping) ->
    throw new NotImplementedError('createQuery')

class FindMany extends AbstractFinder
  createQuery: (collection, selector, options, mapping) ->
    # Set up the Meteor cursor for this selector
    meteor_cursor = collection.find(selector, options)

    # This is the function we want rerun when the result of this query changes
    data_func = ->
      meteor_cursor.rewind()
      meteor_cursor.fetch()

    new MappedQuery(@, data_func, mapping)


class FindOne extends AbstractFinder
  createQuery: (collection, selector, options, mapping) ->
    # This is the function we want rerun when the result of this query changes
    data_func = -> collection.findOne(selector, options)

    new MappedQuery(@, data_func, mapping)

#
# A MappedQuery monitors a finder for changes in its dataset. When it detects
# that a finder's dataset has been invalidated, it reruns data_func (unless
# query.destroy() has been called) and maps the results into finder's target.
#
class MappedQuery
  constructor: (@finder, @data_func, @mapping) ->
    @active = true

  destroy: () ->
    @active = false

  # rerun on invalidation
  onInvalidate: () =>
    @run() if @active

  run: () ->
    # Make use of Meteor's invalidation contexts to trigger a
    # re-mapping of the view model when this finder's dataset changes.
    ctx = new Meteor.deps.Context() # invalidation context
    ctx.on_invalidate(@onInvalidate)
    ctx.run(@execute)

  # Should only be called from Meteor.deps.Context#run
  execute: () =>
    # Fetch fresh data
    data = @data_func()
    if @finder.target and @finder.target.__ko_mapping__
      # This target has already been mapped, so update it
      old = ko.utils.unwrapObservable(@finder.target)
      if _.isUndefined(old) or (old and data and not _.isArray(old) and not _.isArray(data) and @mapping[""].key(old) isnt @mapping[""].key(data))
        # There's either nothing to map into, or the key has changed, so replace the whole target
        @finder.target(ko.utils.unwrapObservable(ko.mapping.fromJS(data, @mapping)))
      else
        # Remap to the existing target
        ko.mapping.fromJS(data, @finder.target)
    else
      # Map to this target for the first time
      result = ko.mapping.fromJS(data, @mapping)
      if ko.isObservable(result)
        @finder.target = result
      else
        @finder.target = ko.observable(result)
        @finder.target.__ko_mapping__ = result.__ko_mapping__

    return @finder.target

ko.exportSymbol('meteor', meteor)
