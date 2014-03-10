class pipes.steps.OAuthStep extends pipes.steps.Step

  oAuthUrl: null

  onRun: ->
    console.log('OAuthStep.run')
    @ajaxStart -> setTimeout (=> @ajaxEnd @end), 1000
    return
    @ajaxStart -> $.get @oAuthUrl,
      success: @ajaxEnd (data) ->
        window.location.href = data.url
        # OH GOD TODO
