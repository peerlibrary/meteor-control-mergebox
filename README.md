control-mergebox
================

This Meteor smart package extends [publish endpoints](http://docs.meteor.com/#/full/meteor_publish)
with control of the [mergebox](https://meteorhacks.com/understanding-mergebox) for a given
publish endpoint function.

Publish function's `this` is extended with `this.disableMergebox()` which when called will
[disable mergebox](https://github.com/meteor/meteor/issues/5645) for current publish endpoint.

By disabling mergebox one chooses to send possibly unnecessary data to clients (because
they already have it) and not maintain on the server side images of clients' data, thus
reducing CPU and memory load on servers.

Server side only.

Installation
------------

```
meteor add peerlibrary:control-mergebox
```

Related projects
----------------

* [meteor-streams](https://arunoda.github.io/meteor-streams/) – allows sending of messages
  from server to client without a mergebox, but then requires manual handling of those
  messages on the client, not using features already provided by Meteor
