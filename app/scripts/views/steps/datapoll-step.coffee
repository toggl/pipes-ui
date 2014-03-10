class pipes.steps.DataPollStep extends pipes.steps.Step

  pollDelay: 5000
  pollDelayIncrement: 0
  # TODO: add limit

  pollUrl: null
  pollTimeout: null
  pollCount: 0 # Used to increase poll interval (3s, 6s, 9s, ...)

  data: null
  key: 'objects'

  # Callback to invoke when data has been received (data, step)
  # Return false if you don't want the step to be automatically end()ed
  dataCallback: ->

  constructor: (options={}) ->
    super(options)
    @key = options.key

  onRun: ->
    console.log('DataPollStep.run')
    @sharedData[@key] =
      objects: [
        {id: 1, name: "User1", email: "user1@gmail.com", checked: false}
        {id: 2, name: "User2", email: "user2@gmail.com", checked: true}
        {id: 3, name: "User3", email: "user3@gmail.com", checked: false}
        {id: 4, name: "User4", email: "user4@gmail.com", checked: false}
      ]
    @ajaxStart -> setTimeout (=> @ajaxEnd @end), 580
    return
    @startPolling()

  onEnd: ->
    @endPolling()

  startPolling: ->
    @pollCount = 0
    @endPolling()
    @setNextPoll()

  setNextPoll: ->
    @pollTimeout = setTimeout @poll, @pollDelay + @pollCount * @pollDelayIncrement

  endPolling: ->
    clearTimeout @pollTimeout

  poll: =>
    @pollCount++
    $.get @pollUrl,
      success: (@data) =>
        if not @data
          @setNextPoll()
        else
          if @dataCallback(@data, @) != false
            @end()

      error: =>
        @setNextPoll()