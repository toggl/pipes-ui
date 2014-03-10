class pipes.steps.DataSubmitStep extends pipes.steps.Step

  url: ''

  # Data tha will be posted is @sharedData[@key]
  key: null

  # Callback to invoke when request has succeeded
  # Return false if you don't want the step to be automatically end()ed
  callback: ->

  constructor: (options={}) ->
    super(options)
    @key = options.key

  onRun: ->
    console.log('DataSubmitStep.run')
    @ajaxStart -> setTimeout (=> @ajaxEnd @end), 500
    setTimeout (=> @view.model.set(status: {type: 'success', message: "Woot done!"})), 2000
    return
    $.post @url,
      data: @sharedData[@key]
      success: (@data) =>
        if @callback(@data, @) != false
          @end()
