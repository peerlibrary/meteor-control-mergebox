if Meteor.isServer
  TestCollection = new Mongo.Collection null

  Meteor.methods
    insertTest: (obj) ->
      TestCollection.insert obj

    updateTest: (selector, query) ->
      TestCollection.update selector, query

    removeTest: (selector) ->
      TestCollection.remove selector

  # "argument" is used so that we can subscribe multiple times with different arguments.
  Meteor.publish 'testPublish', (disableMergebox, argument) ->
    @disableMergebox() if disableMergebox

    handle = TestCollection.find().observeChanges
      added: (id, fields) =>
        @added 'testCollection', id, fields
      changed: (id, fields) =>
        @changed 'testCollection', id, fields
      removed: (id, fields) =>
        @removed 'testCollection', id

    @onStop =>
      handle.stop()

    @ready()

  # "argument" is used so that we can subscribe multiple times with different arguments.
  Meteor.publish 'testPublishFullObserve', (argument) ->
    @disableMergebox()

    handle = TestCollection.find({}, {transform: null}).observe
      added: (newDocument) =>
        @added 'testCollection', newDocument._id, _.omit newDocument, '_id'
      changed: (newDocument, oldDocument) =>
        for field, value of oldDocument when field not of newDocument
          newDocument[field] = undefined
        @changed 'testCollection', newDocument._id, _.omit newDocument, '_id'
      removed: (oldDocument) =>
        @removed 'testCollection', oldDocument._id

    @onStop =>
      handle.stop()

    @ready()

else
  TestCollection = new Mongo.Collection 'testCollection'

class BasicTestCase extends ClassyTestCase
  @testName: 'disable-mergebox - basic'

  setUpServer: ->
    TestCollection.remove {}

  @publishTest: (disableMergebox) ->
    [
      ->
        @assertSubscribeSuccessful 'testPublish', disableMergebox, @expect()
    ,
      ->
        @assertEqual TestCollection.find().fetch(), []

        Meteor.call 'insertTest', {foo: 'test', bar: 123}, @expect (error, documentId) =>
          @assertFalse error, error
          @assertTrue documentId

          @document1Id = documentId
    ,
      @runOnServer ->
        for sessionId, session of Meteor.server.sessions
          if disableMergebox
            @assertEqual session.getCollectionView('testCollection').documents, {}
          else
            @assertNotEqual session.getCollectionView('testCollection').documents, {}
    ,
      ->
        @assertEqual TestCollection.find().fetch(), [{_id: @document1Id, foo: 'test', bar: 123}]

        Meteor.call 'updateTest', {_id: @document1Id}, {$set: {foo: 'test2'}}, @expect (error, count) =>
          @assertFalse error, error
          @assertEqual count, 1
    ,
      @runOnServer ->
        for sessionId, session of Meteor.server.sessions
          if disableMergebox
            @assertEqual session.getCollectionView('testCollection').documents, {}
          else
            @assertNotEqual session.getCollectionView('testCollection').documents, {}
    ,
      ->
        @assertEqual TestCollection.find().fetch(), [{_id: @document1Id, foo: 'test2', bar: 123}]

        Meteor.call 'updateTest', {_id: @document1Id}, {$unset: {foo: ''}}, @expect (error, count) =>
          @assertFalse error, error
          @assertEqual count, 1
    ,
      @runOnServer ->
        for sessionId, session of Meteor.server.sessions
          if disableMergebox
            @assertEqual session.getCollectionView('testCollection').documents, {}
          else
            @assertNotEqual session.getCollectionView('testCollection').documents, {}
    ,
      ->
        @assertEqual TestCollection.find().fetch(), [{_id: @document1Id, bar: 123}]

        Meteor.call 'updateTest', {_id: @document1Id}, {$set: {foo: 'test3'}}, @expect (error, count) =>
          @assertFalse error, error
          @assertEqual count, 1
    ,
      @runOnServer ->
        for sessionId, session of Meteor.server.sessions
          if disableMergebox
            @assertEqual session.getCollectionView('testCollection').documents, {}
          else
            @assertNotEqual session.getCollectionView('testCollection').documents, {}
    ,
      ->
        @assertEqual TestCollection.find().fetch(), [{_id: @document1Id, foo: 'test3', bar: 123}]

        Meteor.call 'removeTest', {_id: @document1Id}, @expect (error, count) =>
          @assertFalse error, error
          @assertEqual count, 1
    ,
      @runOnServer ->
        for sessionId, session of Meteor.server.sessions
          @assertEqual session.getCollectionView('testCollection').documents, {}
    ,
      ->
        @assertEqual TestCollection.find().fetch(), []
    ]

  testClientMergeboxDisabled: @publishTest true

  testClientMergeboxNotDisabled: @publishTest false

  testClientMultipleSubscriptions: [
    ->
      @subscription = @assertSubscribeSuccessful 'testPublish', true, 1, @expect()
      @assertSubscribeSuccessful 'testPublish', true, 2, @expect()
  ,
    ->
      @assertEqual TestCollection.find().fetch(), []

      Meteor.call 'insertTest', {foo: 'test', bar: 123}, @expect (error, documentId) =>
        @assertFalse error, error
        @assertTrue documentId

        @document1Id = documentId
  ,
    ->
      @assertEqual TestCollection.find().fetch(), [{_id: @document1Id, foo: 'test', bar: 123}]

      @subscription.stop()

      # To wait a bit for unsubscribe to happen.
      Meteor.setTimeout @expect(), 10 # ms
  ,
    ->
      # Last change wins, document has been removed.
      @assertEqual TestCollection.find().fetch(), []

      Meteor.call 'updateTest', {_id: @document1Id}, {$set: {foo: 'test2'}}, @expect (error, count) =>
        @assertFalse error, error
        @assertEqual count, 1
  ,
    ->
      # Only the changed field is published.
      @assertEqual TestCollection.find().fetch(), [{_id: @document1Id, foo: 'test2'}]
  ]

  testClientMultipleSubscriptionsFullObserve: [
    ->
      @subscription = @assertSubscribeSuccessful 'testPublishFullObserve', 1, @expect()
      @assertSubscribeSuccessful 'testPublishFullObserve', 2, @expect()
  ,
    ->
      @assertEqual TestCollection.find().fetch(), []

      Meteor.call 'insertTest', {foo: 'test', bar: 123}, @expect (error, documentId) =>
        @assertFalse error, error
        @assertTrue documentId

        @document1Id = documentId
  ,
    ->
      @assertEqual TestCollection.find().fetch(), [{_id: @document1Id, foo: 'test', bar: 123}]

      @subscription.stop()

      # To wait a bit for unsubscribe to happen.
      Meteor.setTimeout @expect(), 10 # ms
  ,
    ->
      # Last change wins, document has been removed.
      @assertEqual TestCollection.find().fetch(), []

      Meteor.call 'updateTest', {_id: @document1Id}, {$set: {foo: 'test2'}}, @expect (error, count) =>
        @assertFalse error, error
        @assertEqual count, 1
  ,
    ->
      # With full observe all fields are published.
      @assertEqual TestCollection.find().fetch(), [{_id: @document1Id, foo: 'test2', bar: 123}]
  ]

ClassyTestCase.addTest new BasicTestCase()
