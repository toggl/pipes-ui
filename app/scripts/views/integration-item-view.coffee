class pipes.views.IntegrationItemView extends Backbone.View
  template: templates['integration-item.html']
  pipesListViewClass: -> pipes.views.PipesListView
  className: 'row integration'

  initialize: ->
    @listenTo @model, 'change', @render
    @cogView = new pipes.views.CogView
      items: [
        {
          name: 'deauthorize'
          label: "Delete authorization"
          fn: @deauthorize
          skip: =>
            not @model.get('authorized')
        }
      ]

  render: ->
    @$el.html @template
      model: @model
      pipeTitles: '[ ' + @model.getPipes().map((p) -> p.get('name')).join(', ') + ' ]'
      showPipeTitles: not @model.get('authorized')
    @cogView.setElement @$('.integration-cog')
    @cogView.render()
    if @model.get('authorized')
      @pipesList = new (@pipesListViewClass())(collection: @model.getPipes()) if not @pipesList
      @pipesList.setElement(@$('.pipes-list'))
      @pipesList.render()
    else
      @configurationView = new IntegrationConfigurationView({@model, el: @$('.integration-configuration')}) if not @configurationView
      @configurationView.setElement(@$('.integration-configuration'))
      @configurationView.render()
    this

  deauthorize: =>
    @model.deleteAuthorization()


class IntegrationConfigurationView extends Backbone.View
  template: templates['integration-configuration.html']

  events:
    'click .button.setup': 'clickEnable'
    'click .button.cancel': 'clickCancel'

  initialize: ->
    @stepper = pipes.integrationStepperFactory(@model, this)
    @listenTo @stepper, 'step', @onStepChange
    @listenTo @stepper, 'error', @onStepError
    @listenTo @stepper, 'ajaxStart', => @ajaxStart()
    @listenTo @stepper, 'ajaxEnd', => @ajaxEnd()
    @stepper.run()
    @setRunning() if not @stepper.current.default

  render: ->
    @$el.html @template model: @model
    @refreshSetupState()

  clickEnable: (e) =>
    e.preventDefault()
    if @stepper.current.default
      @setRunning()
      @stepper.endCurrentStep()

  clickCancel: (e) =>
    e.preventDefault()
    # @overrideStatus null
    @stepper.reset()


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
    # @overrideStatus 'error', "Error: #{message or 'Unknown error'}"

  setRunning: ->
    # @overrideStatus 'running', 'In progress'

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

pipes.integrationStepperFactory = (integration, configurationView) ->
  switch integration.get('id')
    when 'basecamp'
      return new pipes.steps.Stepper
        view: configurationView
        steps: [
          new pipes.steps.NoOpStep(default: true)
          new pipes.steps.OAuth2Step(integration: integration, view: configurationView)
        ]
    when 'freshbooks'
      return new pipes.steps.Stepper
        view: configurationView
        steps: [
          new pipes.steps.NoOpStep(default: true)
          new pipes.steps.OAuth1Step(
            integration: integration
            view: configurationView
            title: "Please enter your Freshbooks account name:"
            inputSuffix: ".freshbooks.com"
          )
        ]
    else
      throw "Integration #{integration.id} doesn't have any configuration steps defined"
