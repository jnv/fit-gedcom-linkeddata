#= require "_helper"

# Add scripts to load to this array. These can be loaded remotely like jquery
# is below, or can use file paths, like 'vendor/underscore'
js = [
  "//cdnjs.cloudflare.com/ajax/libs/jquery/1.8.3/jquery.min.js",
  "//cdnjs.cloudflare.com/ajax/libs/knockout/2.2.0/knockout-min.js",
  "//cdnjs.cloudflare.com/ajax/libs/jqueryui/1.8.24/jquery-ui.min.js"
  "//cdnjs.cloudflare.com/ajax/libs/d3/3.0.1/d3.v3.min.js"
]

# this will fire once the required scripts have been loaded
require js, ->
  $ ->
    console.log 'jquery loaded, dom ready'
