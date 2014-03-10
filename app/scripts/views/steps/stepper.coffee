class pipes.steps.Stepper
  _.extend @prototype, Backbone.Events

  steps: []
  current: null
  currentI: null
  sharedData: null

  constructor: ({@view, @steps}) ->
    @sharedData = {}
    step.initialize @view, @sharedData for step in @steps
    @startStep 0

  startStep: (@currentI) ->
    console.log('startStep', '@currentI:', @currentI, @sharedData)
    @current = @steps[@currentI]
    @current.once 'end', => @startStep (@currentI+1) % @steps.length
    @current.run()
    @trigger 'step', @current, @currentI, @steps

  endCurrentStep: ->
    @current.end()

