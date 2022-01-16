control-mergebox
================

UPDATE: This is now available in [Meteor core](https://docs.meteor.com/api/pubsub.html#Publication-strategies).

This Meteor smart package extends [publish endpoints](http://docs.meteor.com/#/full/meteor_publish)
with control of the [mergebox](https://meteorhacks.com/understanding-mergebox) for a given
publish endpoint function.

Publish function's `this` is extended with `this.disableMergebox()` which when called will
[disable mergebox](https://github.com/meteor/meteor/issues/5645) for current publish endpoint.

By disabling mergebox one chooses to send possibly unnecessary data to clients (because
they already have it) and not maintain on the server side images of clients' data, thus
reducing CPU and memory load on servers.

Server side only (with compatibility changes on the client side).

Installation
------------

```
meteor add peerlibrary:control-mergebox
```

Discussion
----------

This package disables storing the image of client's data on the server side for a given
publish endpoint. This is useful to reduce CPU and memory load on servers, but it makes
server unable to do some things it could do before:

Server does not know which fields client already has and what are their values,
so if your publish function, for example, calls `this.changed('collectionName', id, {foo: 'bar'})`
twice in a row, server will not suppress sending the change twice. This is not so problematic
because it keeps the semantics unchanged, just makes more data go over the wire.

Server also does not know which documents were published from which subscription. This
is more problematic. With mergebox, Meteor tracks which subscription published which documents
(with which fields) and if a document with same ID (and with possibly overlapping fields)
is published from multiple subscriptions, Meteor knows what to do when one subscription removes
a document (or a field) which still exists in other subscriptions. It removes just the fields
previously published by this subscription only, while keeping all other fields for the document
published. With disabled mergebox, when one subscription removes a document or a field that
change is propagated immediately to the client as it is. This is different semantics to
the one with enabled mergebox. So it is important to remember, **with disabled mergebox,
the last document or field change across all subscriptions is always the one propagated to
the client side**. There is simply no state in subscriptions anymore.

The default way to publish collections is to use
[`observeChanges`](http://docs.meteor.com/#/full/observe_changes), explicitly or by returning
a cursor from the publish function. This works well when server uses mergebox because only
changes are really needed. But if you use multiple subscriptions over the same collection with
disabled mergebox you might get strange results. For example, one subscription could remove
a document (which would remove whole document on the client side) and then another subscription
could change one field, which would result in document being re-added on the client side, but
just with that one field. To improve this, one could use
[document-level `observe`](http://docs.meteor.com/#/full/observe):

```javascript
Meteor.publish('myPublish', function () {
  var self = this;

  var handle = collection.find({}, {transform: null}).observe({
    added: function (newDocument) {
      self.added('testCollection', newDocument._id, _.omit(newDocument, '_id'));
    },

    changed: function (newDocument, oldDocument) {
      _.each(oldDocument, function (value, field) {
        if (!_.has(newDocument, field)) {
          newDocument[field] = undefined;
        }
      });

      self.changed('testCollection', newDocument._id, _.omit(newDocument, '_id'));
    },

    removed: function (oldDocument) {
      self.removed('testCollection', oldDocument._id);
    }
  });

  self.onStop(function () {
    handle.stop()
  });

  self.ready();
});
```

But the question is then how much overhead do you gain on the server by using `observe` instead of
`observeChanges`, because `observe` has to cache documents.

In general it is advisable to not use multiple overlapping (in documents) subscriptions when
disabling mergebox. Behavior is then predictable and matches the normal Meteor behavior.

Related projects
----------------

* [meteor-streams](https://arunoda.github.io/meteor-streams/) – allows sending of messages
  from server to client without a mergebox, but then requires manual handling of those
  messages on the client, not using features already provided by Meteor
