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

  query: (key) ->
    throw "Please initialize WindowApi before using it!" if not @initialized
    if @parentSource
      @parentSource.postMessage("TogglPipes.get.#{key}", @parentOrigin)
    else
      switch key
        when 'oAuthQuery'
          setTimeout (=>@trigger 'oAuthQuery', window.location.search), 0
        when 'apiToken'
          apiToken = prompt("Standalone mode: Enter workspace api token", $.cookie 'standalone.apiToken')
          $.cookie 'standalone.apiToken', apiToken or ''
          setTimeout (=>@trigger 'apiToken', apiToken), 0
        when 'workspaceId'
          workspaceId = prompt("Standalone mode: Enter workspace id", $.cookie 'standalone.workspaceId')
          $.cookie 'standalone.workspaceId', workspaceId or ''
          setTimeout (=>@trigger 'workspaceId', +workspaceId), 0
        when 'workspacePremium'
          premium = prompt("Standalone mode: Is workspace premium (1/0)?", $.cookie 'standalone.premium')
          $.cookie 'standalone.workspacePremium', premium or ''
          setTimeout (=>@trigger 'workspacePremium', +premium), 0
        when 'dateFormats'
          setTimeout (=>@trigger 'dateFormats', dateFormats: 'MM/DD/YYYY', timeFormat: 'H:mm', dow: 0), 0
        when 'baseUrl'
          setTimeout (=>@trigger 'baseUrl', '/'), 0

  initialize: ->
    # Fetch document url from the top window and trigger all url-related events

    if window.self == window.top
      @initialized = true
      # setTimeout (=>@trigger 'oAuthQuery', window.location.search), 0
      setTimeout (=>@trigger 'initialize'), 0
    else

      # Wait for initialization from parent before doing anything

      $(window).on 'message', (e) =>
        msg = e.originalEvent.data.split('.')
        return if msg.length < 2 or msg[0] != 'TogglPipes'

        msg = [msg[0]].concat _.flatten msg[1...].join('.').split(':') # ["TogglPipes", ...<:-separated strings>]
        params = msg[2...].join(':')

        if msg[1] == 'initialize'
          @initialized = true
          @parentOrigin = e.originalEvent.origin
          @parentSource = e.originalEvent.source
          @trigger 'initialize'
          return

        return if not @initialized

        switch msg[1]
          when'notify.oAuthQuery'
            oAuthQuery = params
            @trigger 'oAuthQuery', oAuthQuery
          when 'notify.apiToken'
            apiToken = params
            @trigger 'apiToken', apiToken
          when 'notify.workspaceId'
            workspaceId = +params or null
            @trigger 'workspaceId', workspaceId
          when 'notify.workspacePremium'
            premium = !!params
            @trigger 'workspacePremium', premium
          when 'notify.dateFormats'
            [dateFormat, timeFormat, dow] = params.split(',')
            @trigger 'dateFormats',
              dateFormat: dateFormat
              timeFormat: timeFormat
              dow: dow
          when 'notify.baseUrl'
            baseUrl = params
            @trigger 'baseUrl', baseUrl
