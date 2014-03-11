class pipes.steps.OAuthStep extends pipes.steps.Step
  ###
  OAuth step. Uses integration.auth_url.
  Constructs a 'state' param for the oauth url, redirects the browser to the url.
  After a successful authentication, the state parameter is used to restore the oauth process state.
  (see Stepper)
  ###

  tokenUrl: null
  authorizeUrl: null
  code: null

  constructor: (options = {}) ->
    super(options)
    integration = options.pipe.collection.integration
    @id = "#{options.pipe.collection.integration.id}.#{options.pipe.id}.oauth"
    @tokenUrl = integration.get('auth_url').replace('__STATE__', pipes.oauth.createState(@))
    @authorizeUrl = integration.authorizationsUrl()
    @skip = !!options.integration.get('authorization')

  initializeState: (@code) ->

  onRun: ->
    unless @code
      # 1st step
      pipes.redirect @tokenUrl
    else
      # Woot, 2nd step of oauth process, we have recovered state
      @ajaxStart -> $.ajax
        type: 'post'
        url: @authorizeUrl
        data: JSON.stringify(code: @code)
        contentType: 'application/json'
        success: @ajaxEnd ->
          @view.model.collection.integration.set authorization: true
          @end()
