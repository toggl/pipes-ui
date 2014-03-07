class pipes.views.PipeItemView extends Backbone.View
  template: templates['pipe-item.html']
  className: 'row pipe'

  stepper: null

  events:
    'click .button.sync': 'startSync'

  initialize: ->
    console.log('initialize', @model)
    @listenTo @model, 'change:status', @refreshStatus
    @cogView = new pipes.views.CogView
      el: @$('.cog-box')
      items: [
        {name: 'destroy', label: "Destroy all relations", fn: ->}
        pipes.views.CogView.divider
        {name: 'unauthorize', label: "Unauthorize", fn: ->}
      ]
    @metaView = new pipes.views.PipeItemMetaView
      el: @$('.meta')
      model: @model
    @stepper = pipes.getStepper(@model.collection.integration, @model, @)
    @stepper.on 'step', @stepChanged

  stepChanged: (step, i, steps) =>
    @refreshSyncButton()

  startSync: =>
    @model.set status: _.extend({}, @model.get('status'), type: 'in_progress', message: "In progress")
    @stepper.endCurrentStep() if @stepper.current.default

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
    @$('.button.sync').attr 'disabled', not @stepper.current.default or @model.get('status').type != 'success'

  refreshStatus: ->
    @metaView.render()


class pipes.views.PipeItemMetaView extends Backbone.View
  template: templates['pipe-item-meta.html']

  render: =>
    @$el.html @template model: @model
    @

class pipes.steps.Stepper
  _.extend @prototype, Backbone.Events

  steps: []
  current: null
  currentI: null

  constructor: ({@view, @steps}) ->
    step.initialize @view for step in @steps
    @startStep 0

  startStep: (@currentI) ->
    @current = @steps[@currentI]
    @current.once 'end', => @startStep (@currentI+1) % @steps.length
    @current.run()
    @trigger 'step', @current, @currentI, @steps

  endCurrentStep: ->
    @current.end()


class pipes.steps.Step
  _.extend @prototype, Backbone.Events

  view: null # PipeView
  sharedData: null # Data pool that is shared between the steps of a pipe
  default: false # Whether this is the default idle step for a pipe

  constructor: (options={}) ->
    @default = options.default or false

  initialize: (@view, @sharedData) -> # Called by stepper

  run: ->
    # Called by Stepper to start this step
    @onRun()

  end: ->
    # Clean up & signal Stepper to move to the next step
    # Most steps end themselves, but some forever-running steps (IdleState) are forced to end
    @onEnd()
    @trigger 'end'

  onRun: -> # Override me
  onEnd: -> # Override me


class pipes.steps.OAuthStep extends pipes.steps.Step

  oAuthUrl: null

  onRun: ->
    console.log('OAuthStep.run')
    setTimeout (=> @end()), 1000
    return
    $.get @oAuthUrl,
      success: (data) ->
        window.location.href = data.url
        # OH GOD TODO


class pipes.steps.DataPollStep extends pipes.steps.Step

  pollDelay: 5000
  pollDelayIncrement: 0
  # TODO: add limit

  pollUrl: null
  pollTimeout: null
  pollCount: 0 # Used to increase poll interval (3s, 6s, 9s, ...)

  data: null

  # Callback to invoke when data has been received (data, step)
  # Return false if you don't want the step to be automatically end()ed
  dataCallback: ->

  onRun: ->
    console.log('DataPollStep.run')
    setTimeout (=> @end()), 1000
    return
    @startPolling()

  onEnd: ->
    @endPolling()

  startPolling: ->
    @pollCount = 0
    @endPolling()
    @setNextPoll()

  setNextPoll: ->
    @pollTimeout = setTimeout @poll, @pollDelay + @pollCount * @pollDelayIncrement

  endPolling: ->
    clearTimeout @pollTimeout

  poll: =>
    @pollCount++
    $.get @pollUrl,
      success: (@data) =>
        if not @data
          @setNextPoll()
        else
          if @dataCallback(@data, @) != false
            @end()

      error: ->
        @setNextPoll()

class pipes.steps.IdleState extends pipes.steps.DataPollStep
  ###
  Default state for a typical pipe.
  Handles displaying current pipe status (ok, inprogress).
  Prevents sync starting if status == inprogress.
  Also polls for status changes if status == inprogress.
  ###

  pollDelay: 3000
  pollDelayIncrement: 3000

  onRun: ->
    console.log('IdleState.onRun')
    if @view.model.get('status').type == 'in_progress'
      @startPolling()

  dataCallback: (data, self) =>
    # We can simply let the view update itself because this step doesn't draw any custom html
    # and since this is running, the view must be in this step (duh)
    @view.model.set status: data.status
    if data.status.type == 'in_progress'
      @setNextPoll()


class pipes.steps.AccountSelectorStep extends pipes.steps.Step

  listTemplate: templates['steps/account-selector.html']
  accounts: null
  url: null

  onRun: ->
    console.log('AccountSelectorStep.run')
    setTimeout (=> @end()), 1000
    return
    $.get @url,
      success: ({@accounts}) =>
        if not @accounts.length?
          throw 'OMG'
          # TODO
        if @accounts.length > 1
          @displayList @accounts
        else
          @selectAccount @accounts[0].id

  onEnd: ->
    @view.$('.step-container').off '.account-selection'

  displayList: ->
    @view.$('.step-container').html @listTemplate accounts: @accounts
    @view.$('.step-container').on 'click.account-selection', '.button.select-account', (e) =>
      @view.$('.step-container .button.select-account').attr 'disabled', true
      @selectAccount $(e.currentTarget).data('id')

  selectAccount: (@accountId) ->
    @sharedData.accountId = @accountId
    @end()

class pipes.steps.ManualPickerStep extends pipes.steps.Step
  run: -> @end()

pipes.getStepper  = (integration, pipe, pipeView) ->
  console.log('pipes.getStepper', 'integration:', integration, 'pipe:', pipe, 'pipeView:', pipeView)
  switch integration.id
    when 'basecamp'
      switch pipe.id
        when 'users'
          return new pipes.steps.Stepper
            view: pipeView
            steps: [
              new pipes.steps.IdleState(default: true)
              new pipes.steps.OAuthStep()
              new pipes.steps.AccountSelectorStep()
              new pipes.steps.DataPollStep()
              new pipes.steps.ManualPickerStep()
            ]
        else
          throw "Integration #{integration.id} doesn't have logic for pipe #{pipe.id}"
    else
      throw "Integration #{integration.id} doesn't have any pipes defined"

