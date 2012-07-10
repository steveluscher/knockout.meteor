if (Meteor.is_client) {
  // The server is publishing some Todos for us.
  // Let's subscribe to them.
  var Todos = new Meteor.Collection("todos");
  
  // This custom mapping adds a callback to a todo's "done" observable.
  // The callback watches for changes in the "done" property, and syncs
  // them back into the Meteor model.
  //
  // This reveals a weakness in the current implementation of Knockout Meteor;
  // syncing from Meteor->Knockout happens automatically, but syncing back
  // from Knockout->Meteor has to be configured manually.
  //
  // This is both good (you probably want to manage when data is synced back
  // to the database) and bad (you have to write the reverse sync code), but
  // there's probably a way to implement automatic syncing in both directions
  // while still offering enough control over what synced and when.
  //
  // That's your cue to close the loop and send us a pull request!
  //
  var todoMapping = {
    done: {
      // Every time a "done" observable is created, run this function
      create: function(options) {
        var observable = ko.observable(options.data)
        observable.subscribe(function() {
          // Hey! The "done" observable has changed.
          // Let's update the Meteor model, hence persisting the
          // new value, and propagating it to all connected clients.
          var checked = ko.utils.unwrapObservable(this.target);
          Todos.update(ko.utils.unwrapObservable(options.parent._id), { $set: { done: checked } });
        });
        return observable;
      }
    }
  };
  
  var viewModel = {
    // Todos where 'done' == false
    unfinishedTodos: ko.meteor.find(
      Todos,
      {done: false},
      {mapping: todoMapping}
    ),
    // Todos where 'done' == true
    finishedTodos: ko.meteor.find(
      Todos,
      {done: true},
      {mapping: todoMapping}
    ),
    // The todo with the oldest 'created_at' where 'done' == false
    oldestUnfinishedTodo: ko.meteor.findOne(
      Todos,
      {done: false},
      {
        meteor_options: {sort: {created_at: 1}},
        mapping: todoMapping
      }
    )
  };
  
  // Make sure to apply the Knockout bindings after Meteor has started
  Meteor.startup( function() { ko.applyBindings(viewModel); } );
}

if (Meteor.is_server) {
  var Todos = new Meteor.Collection("todos");
  
  Meteor.startup(function () {
    // Bootstrap the DB with some data
    if(Todos.find().count() == 0) {
    
      // Insert some finished todos
      for(var i=1; i<=5; i++) {
        Todos.insert({
          title: 'Todo ' + i,
          done: true,
          created_at: (new Date()).getTime()
        });
        console.log('Created Todo ', i, ' (Finished)');
      }
    
      // Insert some unfinished todos
      for(var i=6; i<=10; i++) {
        Todos.insert({
          title: 'Todo ' + i,
          done: false,
          created_at: (new Date()).getTime()
        });
        console.log('Created Todo ', i, ' (Unfinished)');
      }
    }
  });
}