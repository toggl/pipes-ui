class pipes.steps.Step
  _.extend @prototype, Backbone.Events

  view: null # PipeView
  sharedData: null # Data pool that is shared between the steps of a pipe
  default: false # Whether this is the default idle step for a pipe

  constructor: (options={}) ->
    @default = options.default or false

  initialize: (@view, @sharedData) -> # Called by stepper

  run: =>
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
    fn.call(@)

  ajaxEnd: (fn) ->
    @view.$el.removeClass('spinning-container')
    fn.call(@)
