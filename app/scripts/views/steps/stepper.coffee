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
    step.initialize(view: @view, sharedData: @sharedData, state: pipes.pipeStates[step.id]) for step in @steps
    initialStep = _.findIndex @steps, (step) -> step.id of pipes.pipeStates
    initialStep = 0 if initialStep == -1
    @startStep initialStep

  startStep: (@currentI) ->
    console.log('startStep', 'i:', @currentI, 'step:', @steps[@currentI], 'data:', @sharedData)
    @current = @steps[@currentI]
    @current.once 'end', => @startStep (@currentI+1) % @steps.length
    @current.run()
    @trigger 'step', @current, @currentI, @steps

  endCurrentStep: ->
    @current.end()

