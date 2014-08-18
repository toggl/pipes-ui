class pipes.IntegrationConfigurationView extends Backbone.View
  template: templates['integration-configuration.html']

  events:
    'click .button.setup': 'clickEnable'
    'click .button.cancel': 'clickCancel'

  error: null

  initialize: ->
    @stepper = pipes.integrationStepperFactory(@model, this)
    @listenTo @stepper, 'step', @onStepChange
    @listenTo @stepper, 'error', @onStepError
    @listenTo @stepper, 'ajaxStart', => @ajaxStart()
    @listenTo @stepper, 'ajaxEnd', => @ajaxEnd()
    @stepper.run()

  render: ->
    @$el.html @template
     model: @model
     error: @error
    @refreshSetupState()

  clickEnable: (e) =>
    e.preventDefault()
    @startAuthorization()

  clickCancel: (e) =>
    e.preventDefault()
    @stepper.reset()

  startAuthorization: =>
    if @stepper.current.default
      @stepper.endCurrentStep()

  refreshSetupState: ->
    # Allow setup button & cog only in default step
    # Show cancel button only if not in default step
    @$el.toggleClass 'default-step', @stepper.current.default
    @$('.button.setup')
      .attr 'disabled', not @stepper.current.default
      .children('.button-label').text if @stepper.current.default then "Enable" else "In progress..."

  onStepChange: (step, i, steps) =>
    @refreshSetupState()

  onStepError: (step, message) =>
    @error = "Error: #{message or 'Unknown error'}"
    @render()

  refreshLoading: ->
    @$el.toggleClass('spinning-container', @loading).toggleClass('loading', @loading)

  ajaxStart: (fn = null, context = null) =>
    # Shows UI as 'loading' and optionally runs the callback 'fn' bound to 'context'
    @loading = true
    @refreshLoading()
    fn.call context or this if fn?

  ajaxEnd: (fn = null, context) =>
    # Ends UI 'loading' and optionally runs the callback 'fn' bound to 'context'
    @loading = false
    @refreshLoading()
    fn.call context or this if fn?