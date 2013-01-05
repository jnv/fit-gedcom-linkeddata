require ['jquery', 'rdfstore'], ($, Store)->

  getGraph = (url)->
    $.get '/data/sample.json', (data) ->
      console.log('getGraph')
      console.log data
      return data

  Store.create (store) ->
    store.load 'application/json', getGraph(), 'sample', (success, result) ->
      console.log('Finished!')
      console.log(result)

      store.execute "SELECT DISTINCT ?s  FROM <sample> { ?s ?p ?o }", (succes,result) ->
        console.log(result)
