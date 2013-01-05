define ["rdfstore_frontend"], (RDFStoreFrontend)->
  class Frontend
    'use strict'

    constructor: () ->

    open: (@target, @store)->
      console.log 'Opening frontend'
      @frontend = new RDFStoreFrontend(@target, @store)
      console.log @frontend
