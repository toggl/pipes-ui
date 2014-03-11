class pipes.steps.DataSubmitStep extends pipes.steps.Step

  url: ''
  requestMap: null # Mapping 'query string param name': 'key in sharedData'

  # Callback to invoke when request has succeeded
  # Return false if you don't want the step to be automatically end()ed
  callback: ->

  constructor: (options={}) ->
    super(options)
    @url = options.url
    @requestMap = options.requestMap or {}

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

