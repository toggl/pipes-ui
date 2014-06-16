class pipes.steps.OAuth1Step extends pipes.steps.Step
  ###
  OAuth1 (freshbooks-style) step.
  1. Asks the user for 'account_name'
  2. Constructs a callback url with a 'state' param, imitating oauth2.
  3. Based on the 'callback url' and the user-specified 'account name', asks the API for a URL to direct the user to.
  4. redirects the browser to the url given by the API.
  5. After a successful authentication, the state parameter is used to restore the oauth process state.
  6. The API is notified of a successful auth process by posting the parameters given by the external service (freshbooks).
  ###

  inputTemplate: templates['steps/oauth1-account-selector.html']

  authorizeUrl: null
  code: null
  title: "Please enter your account name:"
  inputSuffix: ""

  constructor: (options = {}) ->
    super(options)
    integration = options.pipe.collection.integration
    @title = options.title if options.title
    @inputSuffix = options.inputSuffix if options.inputSuffix
    @id = "#{integration.id}.#{options.pipe.id}.oauth1"
    @authUrlUrl = integration.authUrlUrl()
    @authorizeUrl = integration.authorizationsUrl()
    @skip = -> integration.get('authorized')

  initializeState: ({@oauth_verifier, @oauth_token, @account_name}) ->
    @sharedData.account_name = @account_name

  fetchAuthUrl: (accountName, options = {}) ->
    @account_name = accountName = encodeURIComponent accountName
    callbackUrl = encodeURIComponent "#{pipes.baseUrl}pipes-oauth/?state=#{pipes.oauth1.createState(@)}"
    @ajaxStart -> $.ajax
      type: 'GET'
      url: "#{@authUrlUrl}?account_name=#{accountName}&callback_url=#{callbackUrl}"
      success: (response) => @ajaxEnd ->
        if response?.auth_url
          options.success?.call(this, response)
        else
          options.error?.call(this, response)
          @trigger('error', this, response?.error or 'Unknown error occurred')
      error: (xhr) => @ajaxEnd ->
        options.error?.call(this, xhr.responseText)
        @trigger 'error', this, xhr.responseText

  onRun: ->
    unless @oauth_token
      # 1st step
      @getContainer().html @inputTemplate {@title, @inputSuffix}
      @getContainer().on 'click.oauth1', '.button.submit', (e) =>
        $(e.currentTarget).attr 'disabled', true
        @fetchAuthUrl @getContainer().find('input.account-name').val(),
          success: (response) ->
            pipes.redirect response.auth_url
    else
      # Woot, 2nd step of oauth process, we have recovered state
      setTimeout (=> pipes.windowApi.sendMessage("scrollTo:#{@view.$el.offset().top}")), 500
      @ajaxStart -> $.ajax
        type: 'POST'
        url: @authorizeUrl
        data: JSON.stringify
          oauth_verifier: @oauth_verifier
          oauth_token: @oauth_token
          account_name: @account_name
        contentType: 'application/json'
        success: => @ajaxEnd ->
          @view.model.collection.integration.set authorized: true
          @end()
        error: (response) => @ajaxEnd ->
          @view.model.collection.integration.set authorized: false
          @trigger 'error', this, response.responseText

  onEnd: ->
    @getContainer().empty().off '.oauth1'
