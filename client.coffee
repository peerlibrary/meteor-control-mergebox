allCollections = {}

Connection = Meteor.connection.constructor

# We patch registerStore to intercept messages and modify them to not throw errors.
originalRegisterStore = Connection::registerStore
Connection::registerStore = (name, wrappedStore) ->
  originalUpdate = wrappedStore.update
  wrappedStore.update = (msg) ->
    collection = allCollections[name]

    # We might still not have a collection for packages defining collections before
    # this package is loaded. But this is OK because those are packages which do not
    # use this package on their collections. If you want to use this package on your
    # collections you have to anyway define a dependency on it.
    return originalUpdate.call @, msg unless collection

    mongoId = MongoID.idParse msg.id
    doc = collection.findOne mongoId

    # If a document is being added, but already exists, just change it.
    if msg.msg is 'added' and doc
      msg.msg = 'changed'
    # If a document is being removed, but it is already removed, do not do anything.
    else if msg.msg is 'removed' and not doc
      return
    # If a document is being changed, but it does not yet exist, just add it.
    else if msg.msg is 'changed' and not doc
      msg.msg = 'added'

      # We do not want to pass on fields marked for clearing.
      for field, value of msg.fields when value is undefined
        delete msg.fields[field]

    originalUpdate.call @, msg

  originalRegisterStore.call @, name, wrappedStore

# We misuse defineMutationMethods to hook into the Mongo.Collection
# constructor and retrieve collection's instance.
originalDefineMutationMethods = Mongo.Collection::_defineMutationMethods
Mongo.Collection::_defineMutationMethods = ->
  if @_connection and @_connection.registerStore
    allCollections[@_name] = @_collection

  originalDefineMutationMethods.call @
