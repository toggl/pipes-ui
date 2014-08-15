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
      setTimeout (=>@trigger 'initialize'), 0
    else
      # Wait for initialization by parent before doing anything
      $(window).on 'message', @onMessage

  sendMessage: (message) ->
    throw "Please initialize WindowApi before using it!" if not @initialized
    if @parentSource
      # If we have parent frame, try to interact with it
      @parentSource.postMessage("TogglPipes.#{message}", @parentOrigin)
    else
      # If no parent frame, fake it with some default data
      switch message
        when 'get.oAuthQuery'
          setTimeout (=>@trigger 'oAuthQuery', window.location.search), 0
        when 'get.apiToken'
          apiToken = prompt("Standalone mode: Enter workspace api token", $.cookie 'standalone.apiToken')
          $.cookie 'standalone.apiToken', apiToken or ''
          setTimeout (=>@trigger 'apiToken', apiToken), 0
        when 'get.workspaceId'
          workspaceId = prompt("Standalone mode: Enter workspace id", $.cookie 'standalone.workspaceId')
          $.cookie 'standalone.workspaceId', workspaceId or ''
          setTimeout (=>@trigger 'workspaceId', +workspaceId), 0
        when 'get.workspacePremium'
          premium = prompt("Standalone mode: Is workspace premium (1/0)?", $.cookie 'standalone.premium')
          $.cookie 'standalone.workspacePremium', premium or ''
          setTimeout (=>@trigger 'workspacePremium', premium != '0'), 0
        when 'get.dateFormats'
          setTimeout (=>@trigger 'dateFormats', dateFormats: 'MM/DD/YYYY', timeFormat: 'H:mm', dow: 0), 0
        when 'get.baseUrl'
          setTimeout (=>@trigger 'baseUrl', '/'), 0

  onMessage: (e) =>
    msg = e.originalEvent.data.split('.')
    return if msg.length < 2 or msg[0] != 'TogglPipes'

    msg = [msg[0]].concat _.flatten msg[1...].join('.').split(':') # ["TogglPipes", ...<:-separated strings>]
    params = msg[2...].join(':')

    if msg[1] == 'initialize'
      @initialized = true
      @parentOrigin = e.originalEvent.origin
      @parentSource = e.originalEvent.source
      @trigger 'initialize', JSON.parse(params)