# require ['jquery', 'rdfstore'], ($, Store)->

#   getGraph = (url)->
#     $.get '/data/sample.json', (data) ->
#       return data

#   Store.create (store) ->
#     store.load 'application/json', getGraph(), 'sample', (success, result) ->
#       console.log('Finished!')
#       console.log(result)

#       store.execute "SELECT DISTINCT ?s  FROM <sample> { ?s ?p ?o }", (succes,result) ->
#         console.log(result)

#       window.Store = store

define ["jquery", "rdfstore"], ($, RDFStore) ->

  class Store
    'use strict'

    prefixes:
      bio: 'http://purl.org/vocab/bio/0.1/'
      rel: 'http://purl.org/vocab/relationship/'

    constructor: () ->
      @store = RDFStore.create()
      for k, url of @prefixes
        @store.setPrefix(k, url)

    load: (url, type) ->
      @store.load type, @downloadGraph(url), 'graph', (success, result) ->
        console.log "Graph loaded", result

    clear: (uri)->
      @store.clear uri, ->
        console.log 'Store cleared'

    downloadGraph: (url) ->
      $.get '/data/sample.json', (data) ->
        return data

    graph: ->
      @store.graph()
