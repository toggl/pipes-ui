class pipes.steps.DataSubmitStep extends pipes.steps.Step
  ###
  Generic data posting step.
  POSTs data to @url. Data is taken from sharedData via @requestMap ({'post param key': 'sharedData key'})
  By default, doesn't do anything with response but end()s immediately.
  ###

  url: ''
  requestMap: null # Mapping 'query string param name': 'key in sharedData'

  # Callback to invoke when request has succeeded
  # Return false if you don't want the step to be automatically end()ed
  callback: ->

  constructor: (options={}) ->
    super(options)
    @url = options.url
    @requestMap = options.requestMap or {}
    @callback = options.callback if options.callback

  getRequestData: ->
    _.mapValues @requestMap, (v, k) => @sharedData[v]

  onRun: ->
    @ajaxStart -> $.ajax
      type: 'post'
      url: @url
      data: JSON.stringify(@getRequestData())
      contentType: 'application/json'
      success: @ajaxEnd (@data) ->
        if @callback(@data, @) != false
          @end()

