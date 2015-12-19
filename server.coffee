originalPublish = Meteor.publish
Meteor.publish = (name, publishFunction) ->
  originalPublish name, (args...) ->
    publish = @

    originalAdded = publish.added
    publish.added = (collectionName, id, fields) ->
      originalCollectionView = @_session.collectionViews[collectionName]
      delete @_session.collectionViews[collectionName]

      try
        originalAdded.call @, collectionName, id, fields
      finally
        if originalCollectionView
          @_session.collectionViews[collectionName] = originalCollectionView
        else
          delete @_session.collectionViews[collectionName]

    originalChanged = publish.changed
    publish.changed = (collectionName, id, fields) ->
      originalCollectionView = @_session.collectionViews[collectionName]
      delete @_session.collectionViews[collectionName]

      # This creates a new collection view.
      collectionView = @_session.getCollectionView collectionName

      # And an empty session document for this id.
      collectionView.documents[id] = new DDPServer._SessionDocumentView()

      # For fields which are being cleared we have to mock some existing
      # value otherwise change will not be send to the client.
      for field, value of fields when value is undefined
        collectionView.documents[id].dataByKey[field] = [subscriptionHandle: @_subscriptionHandle, value: null]

      try
        originalChanged.call @, collectionName, id, fields
      finally
        if originalCollectionView
          @_session.collectionViews[collectionName] = originalCollectionView
        else
          delete @_session.collectionViews[collectionName]

    originalRemoved = publish.removed
    publish.removed = (collectionName, id) ->
      originalCollectionView = @_session.collectionViews[collectionName]
      delete @_session.collectionViews[collectionName]

      # This creates a new collection view and an empty session document for this id.
      @_session.getCollectionView(collectionName).documents[id] = new DDPServer._SessionDocumentView()

      try
        originalRemoved.call @, collectionName, id
      finally
        if originalCollectionView
          @_session.collectionViews[collectionName] = originalCollectionView
        else
          delete @_session.collectionViews[collectionName]

    publishFunction.apply publish, args
