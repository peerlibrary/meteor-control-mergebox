guardObject = {}

extendPublish (name, publishFunction, options) ->
  newPublishFunction = (args...) ->
    publish = @

    disabled = false

    publish.disableMergebox = ->
      disabled = true

    originalAdded = publish.added
    publish.added = (collectionName, id, fields) ->
      return originalAdded.call @, collectionName, id, fields unless disabled

      stringId = @_idFilter.idStringify id

      FiberUtils.synchronize guardObject, "#{collectionName}$#{stringId}", =>
        collectionView = @_session.getCollectionView collectionName

        if collectionView.documents instanceof Map
          originalSessionDocumentView = collectionView.documents.get(stringId)

          try
            # Make sure we start with a clean slate for this document ID.
            collectionView.documents.delete(stringId)

            originalAdded.call @, collectionName, id, fields
          finally
            if originalSessionDocumentView
              collectionView.documents.set(stringId, originalSessionDocumentView)
            else
              collectionView.documents.delete(stringId)

        else
          originalSessionDocumentView = collectionView.documents[stringId]

          try
            # Make sure we start with a clean slate for this document ID.
            delete collectionView.documents[stringId]

            originalAdded.call @, collectionName, id, fields
          finally
            if originalSessionDocumentView
              collectionView.documents[stringId] = originalSessionDocumentView
            else
              delete collectionView.documents[stringId]

    originalChanged = publish.changed
    publish.changed = (collectionName, id, fields) ->
      return originalChanged.call @, collectionName, id, fields unless disabled

      stringId = @_idFilter.idStringify id

      FiberUtils.synchronize guardObject, "#{collectionName}$#{stringId}", =>
        collectionView = @_session.getCollectionView collectionName

        if collectionView.documents instanceof Map
          originalSessionDocumentView = collectionView.documents.get(stringId)

          try
            # Create an empty session document for this id.
            collectionView.documents.set(id, new DDPServer._SessionDocumentView())

            # For fields which are being cleared we have to mock some existing
            # value otherwise change will not be send to the client.
            for field, value of fields when value is undefined
              collectionView.documents.get(id).dataByKey.set(field, [subscriptionHandle: @_subscriptionHandle, value: null])

            originalChanged.call @, collectionName, id, fields
          finally
            if originalSessionDocumentView
              collectionView.documents.set(stringId, originalSessionDocumentView)
            else
              collectionView.documents.delete(stringId)

        else
          originalSessionDocumentView = collectionView.documents[stringId]

          try
            # Create an empty session document for this id.
            collectionView.documents[id] = new DDPServer._SessionDocumentView()

            # For fields which are being cleared we have to mock some existing
            # value otherwise change will not be send to the client.
            for field, value of fields when value is undefined
              collectionView.documents[id].dataByKey[field] = [subscriptionHandle: @_subscriptionHandle, value: null]

            originalChanged.call @, collectionName, id, fields
          finally
            if originalSessionDocumentView
              collectionView.documents[stringId] = originalSessionDocumentView
            else
              delete collectionView.documents[stringId]

    originalRemoved = publish.removed
    publish.removed = (collectionName, id) ->
      return originalRemoved.call @, collectionName, id unless disabled

      stringId = @_idFilter.idStringify id

      FiberUtils.synchronize guardObject, "#{collectionName}$#{stringId}", =>
        collectionView = @_session.getCollectionView collectionName

        if collectionView.documents instanceof Map
          originalSessionDocumentView = collectionView.documents.get(stringId)

          try
            # Create an empty session document for this id.
            collectionView.documents.set(id, new DDPServer._SessionDocumentView())

            originalRemoved.call @, collectionName, id
          finally
            if originalSessionDocumentView
              collectionView.documents.set(stringId, originalSessionDocumentView)
            else
              collectionView.documents.delete(stringId)

        else
          originalSessionDocumentView = collectionView.documents[stringId]

          try
            # Create an empty session document for this id.
            collectionView.documents[id] = new DDPServer._SessionDocumentView()

            originalRemoved.call @, collectionName, id
          finally
            if originalSessionDocumentView
              collectionView.documents[stringId] = originalSessionDocumentView
            else
              delete collectionView.documents[stringId]

    publishFunction.apply publish, args

  [name, newPublishFunction, options]
