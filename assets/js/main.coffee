require.config
  paths:
    jquery: "//cdnjs.cloudflare.com/ajax/libs/jquery/1.8.3/jquery.min"
    knockout: "//cdnjs.cloudflare.com/ajax/libs/knockout/2.2.0/knockout-min"
    jqueryui: "//cdnjs.cloudflare.com/ajax/libs/jqueryui/1.8.24/jquery-ui.min"
    d3: "//cdnjs.cloudflare.com/ajax/libs/d3/3.0.1/d3.v3.min"
    rdfstore: "vendor/rdf_store"
  shim:
    rdfstore:
      exports: "rdfstore"

js = [
  'jquery'
  'jqueryui'
  'store'
  'frontend'
]

# this will fire once the required scripts have been loaded
require js, ->
  $ ->
    console.log 'jquery loaded, dom ready'
