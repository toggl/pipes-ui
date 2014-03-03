class pipes.models.Integration extends Backbone.Model

class pipes.models.IntegrationCollection extends Backbone.Collection
  url: ->
    pipes.apiUrl("/integrations")

class pipes.models.Pipe extends Backbone.Model

class pipes.models.PipeCollection extends Backbone.Collection
  integration: null
  url: ->
    pipes.apiUrl("/integrations/#{@integration.id}/pipes")
