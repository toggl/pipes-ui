class pipes.WindowApi
  ###
  Api for talking with the cross-origin parent frame (toggl.com)
  or the current window through a unified API.
  Toggl automatically posts 'initialize', upon which this immediately requests the document url and api token.
  ###
  _.extend @prototype, Backbone.Events

  initialized: false

  initialize: ->
    # Fetch document url from the top window and trigger a 'documentUrl'

    if window.self == window.top
      @initialized = true
      setTimeout (=>@trigger 'documentUrl', window.location.href), 0
    else

      # Wait for initialization from parent before doing anything

      $(window).on 'message', (e) =>
        msg = e.originalEvent.data.split('.')
        return if msg.length < 2 or msg[0] != 'TogglPipes'

        msg = [msg[0]].concat _.flatten msg[1...].join('.').split(':') # ["TogglPipes", ...<:-separated strings>]

        if msg[1] == 'initialize'
          @initialized = true
          e.originalEvent.source.postMessage("TogglPipes.getApiToken", e.originalEvent.origin)
          e.originalEvent.source.postMessage("TogglPipes.getDocumentUrl", e.originalEvent.origin)

        return if not @initialized

        if msg[1] == 'notifyDocumentUrl'
          documentUrl = msg[2...].join(':')
          @trigger 'documentUrl', documentUrl
        else if msg[1] == 'notifyApiToken'
          apiToken = msg[2...].join(':')
          @trigger 'apiToken', apiToken

