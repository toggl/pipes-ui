class pipes.models.Integration extends Backbone.Model

  pipes: null

  accountsUrl: ->
    pipes.apiUrl("/integrations/#{@id}/accounts")

  authorizationsUrl: ->
    pipes.apiUrl("/integrations/#{@id}/authorizations")

  setPipes: (@pipes) ->
  getPipes: -> @pipes

class pipes.models.IntegrationCollection extends Backbone.Collection

  model: pipes.models.Integration

  url: ->
    pipes.apiUrl("/integrations")

  parse: (response) ->
    # Turn 'pipes' array into a PipeCollection
    models = []
    for iObj in response
      iModel = new @model(_.omit iObj, ['pipes'])
      pipeCollection = new pipes.models.PipeCollection iObj.pipes
      pipeCollection.integration = iModel
      iModel.setPipes pipeCollection
      models.push iModel
    models


class pipes.models.Pipe extends Backbone.Model

  status: (v) ->
    if v
      @set(status: v)
    else
      @get('status') or 'success'

  statusMessage: (v) ->
    if v
      @set(message: v)
    else
      @get('message') or 'Ready'

  lastSync: (v) ->
    if v
      @set(sync_date: v)
    else
      @get('sync_date')

  logLink: (v) ->
    if v
      @set(sync_loc: v)
    else
      @get('sync_log')

class pipes.models.PipeCollection extends Backbone.Collection
  model: pipes.models.Pipe
  integration: null

  url: ->
    pipes.apiUrl("/integrations/#{@integration.id}/pipes")


pipes.models.integrations = new pipes.models.IntegrationCollection()
