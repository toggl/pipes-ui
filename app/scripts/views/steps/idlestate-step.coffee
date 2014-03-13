class pipes.steps.IdleState extends pipes.steps.DataPollStep
  ###
  Default state for a typical pipe.
  Handles displaying current pipe status (ok, inprogress).
  Prevents sync starting if status == inprogress.
  Also polls for status changes if status == inprogress.
  ###

  pollDelay: 1000
  pollDelayIncrement: 2000

  initialize: (options) ->
    super(options)
    @url = @view.model.url() unless @url

  onRun: ->
    if @view.model.status() == 'running'
      @startPolling()

  callback: (response, self) =>
    # We can simply let the view update itself because this step doesn't draw any custom html
    # and since this is running, the view must be in this step (duh)
    @view.model.status response.status
    if response.pipe_status.status == 'running'
      @setNextPoll()
    false

