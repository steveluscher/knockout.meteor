###
Knockout Meteor plugin v0.1
(c) 2012 Steven Luscher, Ruboss - http://ruboss.com/
License: MIT (http://www.opensource.org/licenses/mit-license.php)

Create Knockout Observables from queries against Meteor Collections.
When the results of those queries change, knockout.meteor.js will
ensure that the Observables are updated.

http://github.com/steveluscher/knockout.meteor
###

meteor =
  find: (collection, selector, options = {}) ->
    apply_defaults(options)

    # Set up the Meteor cursor for this selector
    meteor_cursor = collection.find(selector, options.meteor_options)

    # This is the function we want rerun when the result of this query changes
    data_func = ->
      meteor_cursor.rewind()
      data = meteor_cursor.fetch()
      apply_transform(data, options)

    sync({}, data_func, options.mapping)

  findOne: (collection, selector, options = {}) ->
    apply_defaults(options)

    # This is the function we want rerun when the result of this query changes
    data_func = ->
      data = collection.findOne(selector, options.meteor_options)
      apply_transform(data, options)

    sync({}, data_func, options.mapping)

apply_defaults = (options) ->
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

apply_transform = (data, options) ->
  if options.transform
    options.transform(data)
  else
    data

sync = (target, data_func, mapping) ->
  # Make use of Meteor's invalidation contexts to trigger a re-mapping of the
  # view model's observableArray when the Meteor collection changes
  ctx = new Meteor.deps.Context()                        # invalidation context
  ctx.on_invalidate(-> sync(target, data_func, mapping)) # rerun sync() on invalidation
  ctx.run =>
    # Fetch fresh data
    data = data_func()

    if target and target.__ko_mapping__
      # This target has already been mapped, so update it
      if _.isUndefined(ko.utils.unwrapObservable(target))
        # There's nothing to map into, so replace the whole target
        target(ko.mapping.fromJS(data, mapping))
      else
        # Remap to the existing target
        ko.mapping.fromJS(data, target)
    else
      # Map to this target for the first time
      target = ko.mapping.fromJS(data, mapping)

ko.exportSymbol('meteor', meteor)
