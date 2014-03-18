class pipes.steps.Step
  ###
  Generic Step Abstract class.
  Has access to the PipeView via @view
  ###
  _.extend @prototype, Backbone.Events

  view: null # PipeView
  sharedData: null # Data pool that is shared between the steps of a pipe
  default: false # Whether this is the default idle step for a pipe
  skip: null
  id: null # Required for steps that need to recover state after navigating away
  active: false # True if the step is active (current step)

  constructor: (options={}) ->
    @default = options.default or false
    @skip = options.skip

  initialize: ({@view, @sharedData, state}) -> # Called by stepper
    if state
      @initializeState state

  initializeState: (state) -> # Recover state, for steps that leave the page

  run: (options={}) =>
    # Called by Stepper to start this step
    return @end() if @skip?(this)
    @active = true
    @onRun()

  end: (options={}) =>
    # Clean up & signal Stepper to move to the next step
    # Most steps end themselves, but some forever-running steps (IdleState) are forced to end
    @onEnd()
    @active = false
    @trigger 'end' if not options.silent

  onRun: -> # Override me
  onEnd: -> # Override me

  ajaxStart: (fn) ->
    @trigger 'ajaxStart', this
    fn.call this if fn?

  ajaxEnd: (fn) ->
    @trigger 'ajaxEnd', this
    fn.call this if fn?

  getContainer: -> # Return the efficiently cached .step-container of the view
    if not @_container or not $.contains(document.documentElement, @_container[0])
      @_container = @view.$('.step-container')
    @_container
