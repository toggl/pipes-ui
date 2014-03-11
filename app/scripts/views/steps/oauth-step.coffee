class pipes.steps.OAuthStep extends pipes.steps.Step

  tokenUrl: null
  authorizeUrl: null
  code: null

  constructor: (options = {}) ->
    console.log('constructor', 'options:', options)
    super(options)
    @id = "#{options.integration.id}.#{options.pipe.id}.oauth"
    @tokenUrl = options.integration.get('auth_url').replace('__STATE__', pipes.oauth.createState(@))
    @authorizeUrl = options.integration.authorizationsUrl()
    # @skip = !!options.integration.get('authorization')

  initializeState: (@code) ->
    console.log('initializeState', '@code:', @code)

  onRun: ->
    console.log('onRun',@)
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
