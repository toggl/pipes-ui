class pipes.steps.Step
  ###
  Generic Step Abstract class.
  Has access to the PipeView via @view
  ###
  _.extend @prototype, Backbone.Events

  view: null # PipeView
  sharedData: null # Data pool that is shared between the steps of a pipe
  default: false # Whether this is the default idle step for a pipe
  skip: false
  id: null # Required for steps that need to recover state after navigating away

  constructor: (options={}) ->
    @default = options.default or false

  initialize: ({@view, @sharedData, state}) -> # Called by stepper
    if state
      @initializeState state

  initializeState: (state) -> # Recover state, for steps that leave the page

  run: =>
    return @end() if @skip
    # Called by Stepper to start this step
    @onRun()

  end: =>
    # Clean up & signal Stepper to move to the next step
    # Most steps end themselves, but some forever-running steps (IdleState) are forced to end
    @onEnd()
    @trigger 'end'

  onRun: -> # Override me
  onEnd: -> # Override me

  ajaxStart: (fn) ->
    @view.$el.addClass('spinning-container')
    fn.call(@) if fn

  ajaxEnd: (fn) ->
    @view.$el.removeClass('spinning-container')
    fn.call(@) if fn
