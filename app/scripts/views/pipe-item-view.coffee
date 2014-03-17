class pipes.views.PipeItemView extends Backbone.View
  template: templates['pipe-item.html']
  className: 'row pipe'

  stepper: null

  events:
    'click .button.sync': 'startSync'
    'click .log': 'clickLog'
    'click .close-log': 'clickCloseLog'

  initialize: ->
    @listenTo @model, 'change:pipe_status change:configured change:authorized', @refreshStatus
    @cogView = new pipes.views.CogView
      el: @$('.cog-box')
      items: [
        {name: 'teardown', label: "Delete configuration", fn: @teardown}
      ]
    @metaView = new pipes.views.PipeItemMetaView
      el: @$('.meta')
      model: @model
    @stepper = pipes.getStepper(@model.collection.integration, @model, @)
    @stepper.on 'step', @stepChanged
    @setRunning() if not @stepper.current.default

  stepChanged: (step, i, steps) =>
    @refreshSyncButton()

  startSync: =>
    if @stepper.current.default
      @setRunning()
      @stepper.endCurrentStep()

  setRunning: ->
    @model.status 'running'
    @model.statusMessage 'In progress'

  render: =>
    @$el.html @template model: @model
    @cogView.setElement @$('.cog-box')
    @cogView.render()
    @metaView.setElement @$('.meta')
    @metaView.render()
    @$el.foundation()
    @refreshSyncButton()
    @

  refreshSyncButton: ->
    # Allow sync button only in default step if status = ok
    @$('.button.sync')
      .attr 'disabled', not @stepper.current.default or @model.status() != 'success'
      .children('.button-label').text if @stepper.current.default and @model.status() == 'success' then "Sync now" else "In progress..."

  refreshStatus: ->
    @metaView.render()
    @refreshSyncButton()

  teardown: =>
    # Tear down the saved confucation (mostly account_id), setup is handled via steps
    @ajaxStart -> $.ajax
      type: 'DELETE'
      url: "#{@model.url()}/setup"
      success: => @ajaxEnd ->
        @model.set configured: false

  clickLog: (e) =>
    e.preventDefault()
    $.get $(e.currentTarget).attr('href'), (response) =>
      @$('.log-container').show().children('pre').text response

  clickCloseLog: (e) =>
    e.preventDefault()
    @$('.log-container').hide()

  ajaxStart: (fn = null, context = null) ->
    # Shows UI as 'loading' and optionally runs the callback 'fn' bound to 'context'
    @$el.addClass('spinning-container').addClass('loading')
    fn.call(context or this) if fn

  ajaxEnd: (fn = null, context) ->
    # Ends UI 'loading' and optionally runs the callback 'fn' bound to 'context'
    @$el.removeClass('spinning-container').removeClass('loading')
    fn.call(context or this) if fn


class pipes.views.PipeItemMetaView extends Backbone.View
  template: templates['pipe-item-meta.html']

  render: =>
    @$el.html @template model: @model
    @


pipes.getStepper  = (integration, pipe, pipeView) ->
  switch integration.id
    when 'basecamp'
      switch pipe.id
        when 'users'
          return new pipes.steps.Stepper
            view: pipeView
            steps: [
              new pipes.steps.IdleState(default: true)
              new pipes.steps.OAuthStep(pipe: pipe)
              new pipes.steps.AccountSelectorStep(
                skip: pipe.get 'configured'
                outKey: 'accountId'
              )
              new pipes.steps.DataSubmitStep(
                skip: pipe.get 'configured'
                url: "#{pipe.url()}/setup"
                requestMap: {'account_id': 'accountId'}
                callback: ->
                  pipe.set configured: true
              )
              new pipes.steps.DataPollStep(
                url: "#{pipe.url()}/users"
                responseMap: {'users': 'users'} # Mapping 'key in sharedData': 'key in response data'
              )
              new pipes.steps.ManualPickerStep(
                inKey: 'users'
                outKey: 'selectedUsers'
                columns: [{key: 'name', label: "Name", filter: true}, {key: 'email', label: "E-mail", filter: true}]
              )
              new pipes.steps.DataSubmitStep(
                url: "#{pipe.url()}/users"
                requestMap: {'ids': 'selectedUsers'} # Mapping 'query string param name': 'key in sharedData'
              )
            ]
        else
          throw "Integration #{integration.id} doesn't have logic for pipe #{pipe.id}"
    else
      throw "Integration #{integration.id} doesn't have any pipes defined"

