class pipes.WindowApi
  ###
  Api for talking with the cross-origin parent frame (toggl.com)
  or the current window through a unified API.
  Toggl automatically posts 'initialize', upon which this immediately requests the document url workspaceId, api token and others.
  ###
  _.extend @prototype, Backbone.Events

  initialized: false
  parentOrigin: null
  parentSource: null

  initialize: ->
    if window.self == window.top
      # No parent frame: let's just call it 'initialized'
      @initialized = true
      setTimeout (=>
        data =
          oAuthQuery: window.location.search
          baseUrl: 'http://localhost:7001/'
          date:
            dateFormat: 'MM/DD/YYYY'
            timeFormat: 'H:mm'
            dow: 0
        data.apiToken = prompt("Standalone mode: Enter workspace api token", $.cookie 'standalone.apiToken')
        $.cookie 'standalone.apiToken', data.apiToken or ''
        data.workspaceId = prompt("Standalone mode: Enter workspace id", $.cookie 'standalone.workspaceId')
        $.cookie 'standalone.workspaceId', data.workspaceId or ''
        data.workspacePremium = prompt("Standalone mode: Is workspace premium (1/0)?", $.cookie 'standalone.premium')
        $.cookie 'standalone.premium', data.workspacePremium or ''
        @trigger 'initialize', data
      ), 0
    else
      # Wait for initialization by parent before doing anything
      $(window).on 'message', @onMessage

  sendMessage: (message, args) ->
    message = "#{message}:#{JSON.stringify(args or {})}"
    throw "Please initialize WindowApi before using it!" if not @initialized
    if @parentSource
      @parentSource.postMessage("TogglPipes.#{message}", @parentOrigin)
    else
      console.warn("WindowApi.sendMessage #{message} ignored, args:", args)

  onMessage: (e) =>
    msg = e.originalEvent.data.split('.')
    return if msg.length < 2 or msg[0] != 'TogglPipes'

    msg = [msg[0]].concat _.flatten msg[1...].join('.').split(':') # ["TogglPipes", ...<:-separated strings>]
    message = msg[1]
    args = JSON.parse(msg[2...].join(':'))

    if message == 'initialize'
      @initialized = true
      @parentOrigin = e.originalEvent.origin
      @parentSource = e.originalEvent.source
      @trigger 'initialize', args
    else if message == 'isAuthorized'
      @sendMessage 'isAuthorized', {
        integrationId: args.integrationId,
        authorized: pipes.commands.isAuthorized(args.integrationId)
      }
    else if message == 'startAuthorization'
      pipes.commands.startAuthorization(args.integrationId)
    else if message == 'startSync'
      pipes.commands.startSync(args.pipeId)
