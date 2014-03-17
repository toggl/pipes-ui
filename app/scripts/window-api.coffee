class pipes.WindowApi
  ###
  Api for talking with the cross-origin parent frame (toggl.com)
  or the current window through a unified API.
  Toggl automatically posts 'initialize', upon which this immediately requests the document url wid, and api token.
  ###
  _.extend @prototype, Backbone.Events

  initialized: false

  initialize: ->
    # Fetch document url from the top window and trigger all url-related events

    if window.self == window.top
      @initialized = true
      setTimeout (=>@trigger 'oAuthQuery', window.location.search), 0
    else

      # Wait for initialization from parent before doing anything

      $(window).on 'message', (e) =>
        msg = e.originalEvent.data.split('.')
        return if msg.length < 2 or msg[0] != 'TogglPipes'

        msg = [msg[0]].concat _.flatten msg[1...].join('.').split(':') # ["TogglPipes", ...<:-separated strings>]
        params = msg[2...].join(':')

        if msg[1] == 'initialize'
          @initialized = true
          e.originalEvent.source.postMessage("TogglPipes.getApiToken", e.originalEvent.origin)
          e.originalEvent.source.postMessage("TogglPipes.getOAuthQuery", e.originalEvent.origin)
          e.originalEvent.source.postMessage("TogglPipes.getWid", e.originalEvent.origin)
          e.originalEvent.source.postMessage("TogglPipes.getDateFormats", e.originalEvent.origin)

        return if not @initialized

        switch msg[1]
          when'notifyOAuthQuery'
            oAuthQuery = params
            @trigger 'oAuthQuery', oAuthQuery
          when 'notifyApiToken'
            apiToken = params
            @trigger 'apiToken', apiToken
          when 'notifyWid'
            wid = +params or null
            @trigger 'wid', wid
          when 'notifyDateFormats'
            [dateFormat, timeFormat, dow] = params.split(',')
            @trigger 'dateFormats',
              dateFormat: dateFormat
              timeFormat: timeFormat
              dow: dow
