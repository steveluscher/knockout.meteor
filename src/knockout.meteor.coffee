###
Knockout Meteor plugin v0.1
(c) 2012 Steven Luscher, Ruboss - http://ruboss.com/
License: MIT (http://www.opensource.org/licenses/mit-license.php)

Create Knockout Observables from queries against Meteor Collections.
When the results of those queries change, knockout.meteor.js will
ensure that the Observables are updated.

http://github.com/steveluscher/knockout.meteor
###

#
# exported functions are ko.meteor.find and ko.meteor.findOne
#
meteor =
  find: (collection, selector, options = {}) ->
    (new FindMany(collection, selector, options)).run()

  findOne: (collection, selector, options = {}) ->
    (new FindOne(collection, selector, options)).run()


#
# A Finder takes a collection, selector, and options hash and sets up an
# ko.observable (or ko.observableArray) that will get updated whenever the data
# selected by the query changes, or the query parameters themself change.
#
# collection - a Meteor.Collection object, or a Knockout observable (computed or
#              normal) that returns one.
# selector - a Mongo selector, a String, or a Knockout observable (computed or
#            normal) that returns a Mongo selector or a String.
# options - an Object, or a Knockout observable (computed or normal) that
#           returns an Object
#
class AbstractFinder
  constructor: (@collection, @selector, @options = {}) ->
    @target = null

    # listen for changes in arguments
    @collection.subscribe(@run) if ko.isObservable(@collection)
    @selector.subscribe(@run) if ko.isObservable(@selector)
    @options.subscribe(@run) if ko.isObservable(@options)

  run: () =>
    # kill existing query
    @query.destroy() if @query

    # prepare the query arguments
    collection = ko.utils.unwrapObservable(@collection)
    selector = ko.utils.unwrapObservable(@selector)
    options = ko.utils.unwrapObservable(@options)
    @applyDefaults(options)

    # create a MappedQuery (as defined in subclass)
    @query = @createQuery(collection, selector, options)

    # run the damn thing
    @query.run()

  applyDefaults: (options) ->
    _.defaults options,
      mapping: {}
      view_model: null

    # Merge in some mapping defaults
    _.defaults options.mapping,
      # It's important to key collection members by their mongo _id so that the
      # Knockout Mapping plugin can determineif an object is new or old
      key: (item) -> ko.utils.unwrapObservable(item._id),
      copy: []

    # The _id parameter is typically not something that we
    # will change from the UI, so copy it straight into the
    # view model without constructing it as an observable
    if options.mapping.copy and _.isArray(options.mapping.copy)
      options.mapping.copy = _.union(options.mapping.copy, ['_id'])

    # If we were passed a view_model in the options hash,
    # instruct the Knockout Mapping plugin to instantiate
    # each Meteor record as an instance of that model
    if _.isFunction options.view_model
      options.mapping.create = (opts) ->
        view_model = new options.view_model()
        ko.mapping.fromJS(opts.data, options.mapping, view_model)

  createQuery: (collection, selector, options) ->
    throw "Implement in subclass!"


class FindMany extends AbstractFinder
  createQuery: (collection, selector, options) ->
    # Set up the Meteor cursor for this selector
    meteor_cursor = collection.find(selector, options.meteor_options)

    # This is the function we want rerun when the result of this query changes
    data_func = ->
      meteor_cursor.rewind()
      meteor_cursor.fetch()

    new MappedQuery(@, data_func, options.mapping)


class FindOne extends AbstractFinder
  createQuery: (collection, selector, options) ->
    # This is the function we want rerun when the result of this query changes
    data_func = -> collection.findOne(selector, options.meteor_options)

    new MappedQuery(@, data_func, options.mapping)


#
# A MappedQuery is in charge of running data_func within an invalidation context
# and mapping the results into target, and re-run every time the data changes,
# until query.destroy() is called.
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
    # Make use of Meteor's invalidation contexts to trigger a re-mapping of the
    # view model's observableArray when the Meteor collection changes
    ctx = new Meteor.deps.Context() # invalidation context
    ctx.on_invalidate(@onInvalidate)
    ctx.run(@execute)

  # should only be called from Meteor.deps.Context#run
  execute: () =>
    # Fetch fresh data
    data = @data_func()

    if @finder.target and @finder.target.__ko_mapping__
      # This target has already been mapped, so update it
      if _.isUndefined(ko.utils.unwrapObservable(@finder.target))
        # There's nothing to map into, so replace the whole target
        @finder.target(ko.mapping.fromJS(data, @mapping))
      else
        # Remap to the existing target
        ko.mapping.fromJS(data, @finder.target)
    else
      # Map to this target for the first time
      result = ko.mapping.fromJS(data, @mapping)
      @finder.target = if ko.isObservable(result) then result else ko.observable(result)

    return @finder.target


ko.exportSymbol('meteor', meteor)
