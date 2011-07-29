transaction = require './transaction'
pathParser = require './pathParser.server'

transaction.conflict = (txnA, txnB) ->
  # txnA is a new transaction, and txnB is an already committed transaction
  
  # There is no conflict if the paths don't conflict
  return false if !@pathConflict(txnA[3], txnB[3])
  
  # There is no conflict if the transactions are from the same model client
  # and the new transaction was from a later client version.
  # However, this is not true for stores, whose IDs start with a '#'
  if txnA[1].charAt(0) != '#'
    idA = txnA[1].split '.'
    idB = txnB[1].split '.'
    clientIdA = idA[0]
    clientIdB = idB[0]
    if clientIdA == clientIdB
      clientVerA = idA[1] - 0
      clientVerB = idB[1] - 0
      return false if clientVerA > clientVerB
  
  # Ignore transactions with the same ID as an already committed transaction
  return 'duplicate' if txnA[1] == txnB[1]
  
  # There is no conflict if the new transaction has exactly the same method,
  # path, and arguments as the committed transaction
  lenA = txnA.length
  i = 2
  while i < lenA
    return 'conflict' if txnA[i] != txnB[i]
    i++
  return 'conflict' if lenA != txnB.length
  return false

transaction.pathConflict = (pathA, pathB) ->
  # Paths conflict if either is a sub-path of the other
  return true if pathA == pathB
  pathALen = pathA.length
  pathBLen = pathB.length
  return false if pathALen == pathBLen
  if pathALen > pathBLen
    return pathA.charAt(pathBLen) == '.' && pathA.substring(0, pathBLen) == pathB
  return pathB.charAt(pathALen) == '.' && pathB.substring(0, pathALen) == pathA

transaction.journalConflict = (txn, txns) ->
  i = txns.length
  while i--
    return conflict if conflict = @conflict txn, JSON.parse(txns[i])
  return false

transaction.subscribed = (txn, subs) ->
  path = transaction.path txn
  return pathParser.matchesAnyPattern path, subs

module.exports = transaction
