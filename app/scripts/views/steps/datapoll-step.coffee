class pipes.steps.DataPollStep extends pipes.steps.Step
  ###
  Generic data polling step.
  Polls data from @url after @pollDelay ms and by default end()s and stores data in sharedData if any data is received.
  (override @callback to change this behavior)
  Each request can take data from shardData via @requestMap ({'get param': 'sharedData key'})
  Response is stored into sharedData through @responseMap ({'sharedData key': 'response json key'})
  (use blank json key to store the whole response)
  ###

  pollDelay: 1000
  pollDelayIncrement: 0
  # TODO: add limit

  url: null
  pollTimeout: null
  pollCount: 0 # Used to increase poll interval (3s, 6s, 9s, ...)

  requestMap: null # Mapping 'query string param name': 'key in sharedData'
  responseMap: null
  forceFirst: true # send force=true on first request (default behavior to trigger fetching on the backend)

  # Callback to invoke when data has been received
  # Return false if you don't want the step to be automatically end()ed
  # Default behaviour: uses responseMap to map response values to sharedData
  successCallback: (response, step) ->
    for k, v of @responseMap
      @sharedData[k] = if v then response[v] else response

  errorCallback: (response, step) ->
    step.trigger 'error', step, response

  constructor: (options = {}) ->
    super(options)
    @requestMap = options.requestMap
    @responseMap = options.responseMap
    @url = options.url
    @forceFirst = options.forceFirst if 'forceFirst' in options

  getRequestData: ->
    data =_.mapValues @requestMap, (v, k) => @sharedData[v]
    data.force = true if @forceFirst and @pollCount == 1
    data

  onRun: ->
    @startPolling()

  onEnd: ->
    @endPolling()

  startPolling: ->
    @pollCount = 0
    @endPolling()
    @ajaxStart()
    @poll()

  setNextPoll: ->
    @pollTimeout = setTimeout @poll, @pollDelay + (@pollCount - 1) * @pollDelayIncrement

  endPolling: ->
    @ajaxEnd()
    clearTimeout @pollTimeout

  poll: =>
    @pollCount++
    $.ajax
      type: 'GET'
      url: @url
      data: @getRequestData()
      success: (responseData) =>
        return if not @active # Oops, someone canceled this action
        if not responseData
          @setNextPoll()
        else if responseData.error
          @errorCallback(responseData.error, this)
        else
          if @successCallback(responseData, this) != false
            @end()
      error: (response) =>
        return if not @active # Oops, someone canceled this action
        @errorCallback(response.responseText, this)
