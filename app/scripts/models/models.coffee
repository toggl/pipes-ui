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
      @set(pipe_status: _.extend {}, @get('pipe_status'), status: v)
    else
      @get('pipe_status')?.status or 'success'

  statusMessage: (v) ->
    if v
      @set(pipe_status: _.extend {}, @get('pipe_status'), message: v)
    else
      @get('pipe_status')?.message or 'Ready'

  lastSync: (v) ->
    if v
      @set(pipe_status: _.extend {}, @get('pipe_status'), sync_date: v)
    else
      str = @get('pipe_status')?.sync_date
      return null if not str
      moment(str)

  logLink: (v) ->
    if v
      @set(pipe_status: _.extend {}, @get('pipe_status'), sync_log: v)
    else
      @get('pipes_status')?.sync_log or null

  lastSyncHuman: ->
    d = @lastSync()
    if d then d.calendar() else null

class pipes.models.PipeCollection extends Backbone.Collection
  model: pipes.models.Pipe
  integration: null

  url: ->
    pipes.apiUrl("/integrations/#{@integration.id}/pipes")


pipes.models.integrations = new pipes.models.IntegrationCollection()
