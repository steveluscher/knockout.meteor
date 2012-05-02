# Knockout Meteor #

Creates Knockout Observables based on queries against Meteor Collections. When the results of those queries change, Knockout Meteor will ensure that the associated Observables are updated.

## Why? ##

[Knockout](http://knockoutjs.com) lets you create complex associations between Javascript model data and DOM elements using an expressive and declarative binding syntax. The Knockout Mapping plugin excels at atomically updating your Javascript models (and hence your UI) based on incoming data, updating only that which has changed. These are two strengths that Meteor does not currently possess.

[Meteor](http://meteor.com), however, makes it incredibly easy to ferry model data back and forth between a server and its connected clients. Knockout Meteor acts as a bridge between these two frameworks. It lets you construct queries against Meteor Collections that behave like Knockout Observables that update themselves atomically and automatically when the results of those queries change.

## Usage ##

Let's assume there exists a `Meteor.Collection` called `Todos`, and that our view model wants to track unfinished todos, finished todos, and the oldest unfinished todo.

    var Todos = new Meteor.Collection("todos");

### In the view model: ###

Use `ko.meteor.find()` and `ko.meteor.findOne()` like you would normally use `ko.observableArray()` and `ko.observable()`:

    var viewModel = {
      unfinishedTodos: ko.meteor.find(Todos, {done: false}),
      finishedTodos: ko.meteor.find(Todos, {done: true}),
      oldestUnfinishedTodo: ko.meteor.findOne(Todos, {done: true}, {meteor_options: {sort: {created_at:1}}})
    };
    Meteor.startup( function() { ko.applyBindings(viewModel); } );

### In the HTML: ###

Since `ko.meteor.find()` and `ko.meteor.findOne()` return instances of `ko.observableArray` and `ko.observable` respectively, you can bind to them in the way you're used to:

    <ul data-bind="foreach: unfinishedTodos">
      <li data-bind="text: title"></li>
    </ul>

Any update to the Meteor `Todos` collection will now trigger a UI refresh. This includes local updates, and updates pushed from the server.

## Documentation ##

`ko.meteor.find()` and `ko.meteor.findOne()` share the same method signature.

    ko.meteor.find( collection, selector[, options] )
    ko.meteor.findOne( collection, selector[, options] )

### The `collection` argument ###

Must be an instance of a `Meteor.Collection`

### The `selector` argument ###

A Mongo selector, or String. See the Meteor documentation on [`find()`](http://docs.meteor.com/#find) or [`findOne()`](http://docs.meteor.com/#findone) for more information.

### The `options` argument ###

An optional Object. Recognizes the following keys:

* `view_model` – an object constructor.

> The mapper will instantiate an object using this constructor, then map each record in the Meteor Collection to the resulting instance.

* `meteor_options` – additional configuration for `Meteor.Collection.find()` or `Meteor.Collection.findOne()`.

> See the Meteor documentation on the `options` argument of [`find()`](http://docs.meteor.com/#find) and [`findOne()`](http://docs.meteor.com/#findone) for more information.
 
* `mapping` – additional configuration for the Knockout Mapping plugin.

> See the "[Advanced Usage](http://knockoutjs.com/documentation/plugins-mapping.html#advanced_usage)" section of the Knockout Mapping documentation for more information.

## Requirements ##

* Meteor *(>= 0.3.5)* – https://github.com/meteor/meteor
* knockout.js *(>= 2.1.0rc2)* – https://github.com/SteveSanderson/knockout
* knockout.mapping.js *(>= 2.1.2)* - https://github.com/SteveSanderson/knockout.mapping

## Developing ##

Want to contribute? Great! To hack away you'll want a clone of this repo, and the Coffeescript compiler.

    > git clone https://github.com/steveluscher/knockout.meteor.git
    > cd knockout.meteor
    > npm install

`make compile` will compile the Coffeescript file in `./src` into Javascript files located in `./build` and `./example/client`. Use `make watch` if you would like the compiler to run every time you save.

## Giving thanks ##

Web development pays bills, but my real passion is music. If you found this code useful, the best way to say thank you is to support my band [Lakefield](http://lakefieldmusic.com) ([@lakefieldmusic](http://twitter.com/lakefieldmusic)).

## License ##

Copyright (C) 2012 Steven Luscher ([@steveluscher](http://twitter.com/steveluscher)) and Ruboss Technology Coporation ([@rubosstech](http://twitter.com/rubosstech)) – Released under the [MIT License](http://www.opensource.org/licenses/mit-license.php)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.