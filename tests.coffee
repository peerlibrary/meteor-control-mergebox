if Meteor.isServer
  TestCollection = new Meteor.Collection null

  Meteor.methods
    insertTest: (obj) ->
      TestCollection.insert obj

    updateTest: (selector, query) ->
      TestCollection.update selector, query

    removeTest: (selector) ->
      TestCollection.remove selector

  Meteor.publish 'testPublish', ->
    @disableMergebox()

    TestCollection.find().observeChanges
      added: (id, fields) =>
        @added 'testCollection', id, fields
      changed: (id, fields) =>
        @changed 'testCollection', id, fields
      removed: (id, fields) =>
        @removed 'testCollection', id

    @ready()

else
  TestCollection = new Meteor.Collection 'testCollection'

class BasicTestCase extends ClassyTestCase
  @testName: 'disable-mergebox - basic'

  testClientBasic: [
    ->
      @assertSubscribeSuccessful 'testPublish', @expect()
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
        @assertEqual session.getCollectionView('testCollection').documents, {}
  ,
    ->
      @assertEqual TestCollection.find().fetch(), [{_id: @document1Id, foo: 'test', bar: 123}]

      Meteor.call 'updateTest', {_id: @document1Id}, {$set: {foo: 'test2'}}, @expect (error, count) =>
        @assertFalse error, error
        @assertEqual count, 1
  ,
    @runOnServer ->
      for sessionId, session of Meteor.server.sessions
        @assertEqual session.getCollectionView('testCollection').documents, {}
  ,
    ->
      @assertEqual TestCollection.find().fetch(), [{_id: @document1Id, foo: 'test2', bar: 123}]

      Meteor.call 'updateTest', {_id: @document1Id}, {$unset: {foo: ''}}, @expect (error, count) =>
        @assertFalse error, error
        @assertEqual count, 1
  ,
    @runOnServer ->
      for sessionId, session of Meteor.server.sessions
        @assertEqual session.getCollectionView('testCollection').documents, {}
  ,
    ->
      @assertEqual TestCollection.find().fetch(), [{_id: @document1Id, bar: 123}]

      Meteor.call 'updateTest', {_id: @document1Id}, {$set: {foo: 'test3'}}, @expect (error, count) =>
        @assertFalse error, error
        @assertEqual count, 1
  ,
    @runOnServer ->
      for sessionId, session of Meteor.server.sessions
        @assertEqual session.getCollectionView('testCollection').documents, {}
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

ClassyTestCase.addTest new BasicTestCase()
