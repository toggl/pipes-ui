class pipes.views.PipeItemView extends Backbone.View
  template: templates['pipe-item.html']
  className: 'row pipe'

  stepper: null

  events:
    'click .button.sync': 'startSync'
    'click .log': 'clickLog'
    'click .close-log': 'clickCloseLog'
    'click .cancel': 'clickCancel'

  initialize: ->
    @listenTo @model, 'change:pipe_status change:configured change:authorized', @refreshStatus
    @cogView = new pipes.views.CogView
      el: @$('.cog-box')
      items: [
        {name: 'teardown', label: "Delete configuration", fn: @teardown, skip: => not @model.get('configured')}
      ]
    @metaView = new pipes.views.PipeItemMetaView
      el: @$('.meta')
      model: @model
    @stepper = pipes.getStepper(@model.collection.integration, @model, this)
    @stepper.on 'step', @onStepChange
    @stepper.on 'error', @onStepError
    @stepper.on 'beforeEnd', @onStepperBeforeEnd
    @setRunning() if not @stepper.current.default

  onStepChange: (step, i, steps) =>
    @refreshSyncState()

  onStepError: (step, message) =>
    @overrideStatus 'fail', "Error: #{message}"
    @stepper.current.poll() # Sync once through IdleStep TODO: uncouple PipeItemView from stepper.steps[0] here!

  setRunning: ->
    @overrideStatus 'running', 'In progress'

  onStepperBeforeEnd: =>
    # No steps left, stepper has successfully rolled over to first
    # We know that backend should have set 'running' by now: sync it manually (upon which IdleState starts polling)
    @model.setStatus @metaView.statusOverride.status, @metaView.statusOverride.message
    @overrideStatus null # Take real status from model

  overrideStatus: (status = null, message = null) ->
    if status
      @metaView.statusOverride = status: status, message: message or @model.getStatusMessage()
    else
      @metaView.statusOverride = null
    @refreshStatus()

  startSync: =>
    if @stepper.current.default
      @setRunning()
      @stepper.endCurrentStep()

  render: =>
    @$el.html @template
      model: @model
      status: @metaView.getStatusObject()
    @cogView.setElement @$('.cog-box')
    @cogView.render()
    @metaView.setElement @$('.meta')
    @metaView.render()
    @$el.foundation()
    @refreshSyncState()
    this

  refreshSyncState: ->
    # Allow sync button & cog only in default step
    @$el.toggleClass 'default-step', @stepper.current.default
    @$('.button.sync')
      .attr 'disabled', not @stepper.current.default
      .children('.button-label').text if @stepper.current.default and @model.getStatus() == 'success' then "Sync now" else "In progress..."
    # Show cancel button only if not in default step

  refreshStatus: ->
    @metaView.render()
    @refreshSyncState()
    @cogView.render()

  teardown: =>
    # Tear down the saved configuration (mostly account_id), setup is handled via steps
    @ajaxStart -> $.ajax
      type: 'DELETE'
      url: "#{@model.url()}/setup"
      success: => @ajaxEnd ->
        @model.set configured: false
      error: (response) => @ajaxEnd ->
        @model.setStatus 'fail', "Error: #{response.responseText}"

  clickLog: (e) =>
    e.preventDefault()
    $.get $(e.currentTarget).attr('href'), (response) =>
      @$('.log-container').show().children('pre').text response
      @$('a.log').hide()

  clickCloseLog: (e) =>
    e.preventDefault()
    @$('.log-container').hide()
    @$('a.log').show()

  clickCancel: (e) =>
    e.preventDefault()
    @stepper.reset()

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
  statusOverride: null # Use this to display a different status than the one in the model

  getStatusObject: ->
    @statusOverride or {status: @model.getStatus(), message: @model.getStatusMessage()}

  render: =>
    @$el.html @template
      model: @model
      status: @getStatusObject()
    this


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
                skip: -> pipe.get 'configured'
                outKey: 'accountId'
              )
              new pipes.steps.DataSubmitStep(
                skip: -> pipe.get 'configured'
                url: "#{pipe.url()}/setup"
                requestMap: {'account_id': 'accountId'}
                successCallback: ->
                  pipe.set configured: true
              )
              new pipes.steps.DataPollStep(
                url: "#{pipe.url()}/users"
                responseMap: {'users': 'users'} # Mapping 'key in sharedData': 'key in response data'
              )
              new pipes.steps.ManualPickerStep(
                title: "Select users to import"
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

