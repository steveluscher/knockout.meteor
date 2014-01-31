People = new Meteor.Collection("people");
Cats = new Meteor.Collection("cats");

if (Meteor.isClient) {

  // basics
  var collection = ko.observable("People");
  var minAge = ko.observable(4);
  var maxAge = ko.observable(10);
  var sortField = ko.observable("Age");
  var sortAsc = ko.observable(true);

  // computed observables to use as arguments for finders
  var meteorCollection = ko.computed(function() { return this[collection()]; }, this);

  var selector = ko.computed(function() {
    return { $and: [{ age: { $gte: parseInt(minAge()) } }, { age: { $lte: parseInt(maxAge()) } }] };
  });

  var options = ko.computed(function() {
    var options = { sort: {} };
    options.sort[sortField().toLowerCase()] = sortAsc() ? 1 : -1;
    return options;
  });

  // finders!
  var findMany = ko.meteor.find(meteorCollection, selector, options);
  var findOne = ko.meteor.findOne(meteorCollection, selector, options);

  // set up view model to bind to UI
  var viewModel = {
    collection: collection,
    collections: ["Cats", "People"],
    minAge: minAge,
    maxAge: maxAge,
    sortField: sortField,
    sortFields: ["Age", "Name"],
    sortAsc: sortAsc,

    findMany: findMany,
    findOne: findOne
  };

  // for debugging
  var pp = function(obj) { return obj ? (_.isArray(obj) ? _.map(obj, pp) : obj.name() + ":" + obj.age()) : obj; };
  findMany.subscribe(function(val) { console.log("findMany changed", pp(val)); });
  findOne.subscribe(function(val) {
    console.log("findOne changed", pp(val));
    if (val) {
      val.name.subscribe(function(val) { console.log("findOne.name changed", val); });
      val.age.subscribe(function(val) { console.log("findOne.age changed", val); });
    }
  });

  // boot!
  Meteor.startup( function() { ko.applyBindings(viewModel); } );
}

if (Meteor.isServer) {

  Meteor.startup(function () {
    // Bootstrap the DB with some data
    if(People.find().count() == 0) {
      People.insert({name: "Betty", age: 6})
      People.insert({name: "Sally", age: 1})
      People.insert({name: "Nancy", age: 9})
      People.insert({name: "Fred", age: 5})
      People.insert({name: "Robert", age: 12})
      People.insert({name: "Zora", age: 4})
      People.insert({name: "Richard", age: 10})
    }
    if(Cats.find().count() == 0) {
      Cats.insert({name: "Frodo", age: 2})
      Cats.insert({name: "Samwise", age: 3})
      Cats.insert({name: "Gollum", age: 12})
      Cats.insert({name: "Gimli", age: 4})
      Cats.insert({name: "Faramir", age: 9})
    }
  });
}
