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
    @stepper = pipes.stepperFactory(@model.collection.integration, @model, this)
    @listenTo @stepper, 'step', @onStepChange
    @listenTo @stepper, 'error', @onStepError
    @listenTo @stepper, 'beforeEnd', @onStepperBeforeEnd
    @listenTo @stepper, 'ajaxStart', => @ajaxStart()
    @listenTo @stepper, 'ajaxEnd', => @ajaxEnd()
    @setRunning() if not @stepper.current.default

  onStepChange: (step, i, steps) =>
    @refreshSyncState()

  onStepError: (step, message) =>
    console.log('onStepError', 'step:', step, 'message:', message)
    @overrideStatus 'fail', "Error: #{message or 'Unknown error'}"
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
    # Show cancel button only if not in default step
    @$el.toggleClass 'default-step', @stepper.current.default
    @$('.button.sync')
      .attr 'disabled', not @stepper.current.default
      .children('.button-label').text if @stepper.current.default and @model.getStatus() == 'success' then "Sync now" else "In progress..."

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
    fn.call context or this if fn?

  ajaxEnd: (fn = null, context) ->
    # Ends UI 'loading' and optionally runs the callback 'fn' bound to 'context'
    @$el.removeClass('spinning-container').removeClass('loading')
    fn.call context or this if fn?


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
