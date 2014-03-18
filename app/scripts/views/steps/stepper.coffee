class pipes.steps.Stepper
  ###
  Handles stepping sequences for PipeViews and also restores state if a known state string is found
  in documentUrl (used by oauth).
  ###
  _.extend @prototype, Backbone.Events

  steps: []
  current: null
  currentI: null
  sharedData: null

  constructor: ({@view, @steps}) ->
    @sharedData = {}
    for step in @steps
      step.initialize(view: @view, sharedData: @sharedData, state: pipes.pipeStates[step.id])
      step.on 'error', @onStepError
      step.on 'ajaxStart', => @trigger 'ajaxStart', step
      step.on 'ajaxEnd', => @trigger 'ajaxEnd', step
    initialStep = _.findIndex @steps, (step) -> step.id of pipes.pipeStates
    initialStep = 0 if initialStep == -1
    @startStep initialStep

  startStep: (@currentI) ->
    console.log('startStep', 'i:', @currentI, 'step:', @steps[@currentI], 'data:', @sharedData)
    @current = @steps[@currentI]
    @current.once 'end', => @startStep (@currentI+1) % @steps.length
    @trigger 'beforeStep', @current, @currentI, @steps
    @trigger 'beforeEnd', @current, @currentI, @steps if @currentI == 0
    @current.run()
    @trigger 'step', @current, @currentI, @steps
    @trigger 'end', @current, @currentI, @steps if @currentI == 0

  endCurrentStep: ->
    @current.end()

  reset: ->
    @current.end(silent: true)
    @current.off 'end'
    @startStep 0

  onStepError: (args...) =>
    @reset() unless @currentI == 0 # Auto-reset on all errors, no smart error handling here
    @trigger.apply this, ['error'].concat(args) # Manual propagation

