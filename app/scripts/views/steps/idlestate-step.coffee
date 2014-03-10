class pipes.steps.IdleState extends pipes.steps.DataPollStep
  ###
  Default state for a typical pipe.
  Handles displaying current pipe status (ok, inprogress).
  Prevents sync starting if status == inprogress.
  Also polls for status changes if status == inprogress.
  ###

  pollDelay: 3000
  pollDelayIncrement: 3000

  onRun: ->
    console.log('IdleState.onRun')
    if @view.model.get('status').type == 'in_progress'
      @startPolling()

  dataCallback: (data, self) =>
    # We can simply let the view update itself because this step doesn't draw any custom html
    # and since this is running, the view must be in this step (duh)
    @view.model.set status: data.status
    if data.status.type == 'in_progress'
      @setNextPoll()

