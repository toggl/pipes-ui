class pipes.steps.IdleState extends pipes.steps.DataPollStep
  ###
  Default state for a typical pipe.
  Handles displaying current pipe status (ok, inprogress).
  Prevents sync starting if status == inprogress.
  Also polls for status changes if status == inprogress.
  ###

  pollDelay: 500
  pollDelayIncrement: 500
  forceFirst: false

  initialize: (options) ->
    super(options)
    @url = @view.model.url() unless @url

  onRun: ->
    if @view.model.getStatus() == 'running'
      @startPolling()

  callback: (response, self) =>
    # We can simply let the view update itself because this step doesn't draw any custom html
    # and since this is running, the view must be in this step (duh)
    @view.model.setLastSync response.pipe_status.sync_date, silent: true
    @view.model.setLogLink response.pipe_status.sync_log, silent: true
    @view.model.setStatus response.pipe_status.status, response.pipe_status.message

    if @view.model.getStatus() == 'running'
      @setNextPoll()
    else
      @endPolling()

    return false # Never exit this step

