class pipes.steps.DataSubmitStep extends pipes.steps.Step
  ###
  Generic data posting step.
  POSTs data to @url. Data is taken from sharedData via @requestMap ({'post param key': 'sharedData key'})
  By default, doesn't do anything with response but end()s immediately.
  ###

  url: ''
  requestMap: null # Mapping 'query string param name': 'key in sharedData'
  forceFirst: false

  # Callback to invoke when request has succeeded
  # Return false if you don't want the step to be automatically end()ed
  successCallback: (response, step) ->

  errorCallback: (response, step) ->
    step.trigger 'error', step, response.responseText

  constructor: (options={}) ->
    super(options)
    @url = options.url
    @requestMap = options.requestMap or {}
    @successCallback = options.successCallback if options.successCallback

  getRequestData: ->
    _.mapValues @requestMap, (v, k) => @sharedData[v]

  onRun: ->
    @ajaxStart -> $.ajax
      type: 'POST'
      url: @url
      data: JSON.stringify(@getRequestData())
      contentType: 'application/json'
      success: (@data) =>
        return if not @active # Oops, someone canceled this action
        if @successCallback(@data, @) != false
          @ajaxEnd()
          @end()
      error: (response) =>
        return if not @active # Oops, someone canceled this action
        @errorCallback(response, this)
        @ajaxEnd()

