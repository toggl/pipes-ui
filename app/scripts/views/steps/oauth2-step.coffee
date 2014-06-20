class pipes.steps.OAuth2Step extends pipes.steps.Step
  ###
  OAuth2 step. Uses integration.auth_url.
  Constructs a 'state' param for the oauth url, redirects the browser to the url.
  After a successful authentication, the state parameter is used to restore the oauth process state.
  (see Stepper)
  ###

  tokenUrl: null
  authorizeUrl: null
  code: null

  constructor: (options = {}) ->
    super(options)
    @integration = options.integration
    @id = options.id or "#{@integration.id}.oauth2"
    @tokenUrl = @integration.get('auth_url').replace('__STATE__', pipes.oauth2.createState(@))
    @authorizeUrl = @integration.authorizationsUrl()
    @skip = -> @integration.get('authorized')

  initializeState: ({@code}) ->

  onRun: ->
    unless @code
      # 1st step
      pipes.redirect @tokenUrl
    else
      # Woot, 2nd step of oauth process, we have recovered state
      setTimeout (=> pipes.windowApi.sendMessage("scrollTo:#{@view.$el.offset().top}")), 500
      @ajaxStart -> $.ajax
        type: 'POST'
        url: @authorizeUrl
        data: JSON.stringify(code: @code)
        contentType: 'application/json'
        success: => @ajaxEnd ->
          @integration.set authorized: true
          @end()
        error: (response) => @ajaxEnd ->
          @integration.set authorized: false
          @trigger 'error', this, response.responseText
