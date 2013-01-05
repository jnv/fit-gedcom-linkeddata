require.config
  paths:
    jquery: "//cdnjs.cloudflare.com/ajax/libs/jquery/1.8.3/jquery.min"
    knockout: "//cdnjs.cloudflare.com/ajax/libs/knockout/2.2.0/knockout-min"
    jqueryui: "//cdnjs.cloudflare.com/ajax/libs/jqueryui/1.8.24/jquery-ui.min"
    d3: "//cdnjs.cloudflare.com/ajax/libs/d3/3.0.1/d3.v3.min"
    rdfstore: "vendor/rdf_store"
    rdfstore_frontend: "vendor/rdfstore_frontend"
    linkedvis: "vendor/linkedvis"
    sizzle: "//cdnjs.cloudflare.com/ajax/libs/sizzle/1.4.4/sizzle.min.js"
    jquerytmpl: "http://ajax.aspnetcdn.com/ajax/jquery.templates/beta1/jquery.tmpl"
  shim:
    rdfstore:
      exports: "rdfstore"

js = [
  'jquery'
  'store'
  'frontend'
]

# this will fire once the required scripts have been loaded
require js, ($, Store, Frontend)->
  $ ->
    console.log 'jquery loaded, dom ready'

    store = new Store()
    store.load('/data/sample.json', 'application/json')
    window.Store = store

    frontend = new Frontend()
    frontend.open('#frontend', store.store)

