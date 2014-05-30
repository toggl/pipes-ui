#
# Single point of entry for the whole application is PipesApp.initialize
# Initialize stuff there !
#

$(document).foundation()
$ -> window.pipes.initialize()

# Global custom checkboxes (structure: input.custom.checkbox + span.checkbox)

$(document.body).on 'click', 'span.checkbox', (e) ->
  $input = $(e.currentTarget).siblings('input:checkbox.custom.checkbox')
  $input.prop 'checked', not $input.prop('checked')
  $input.change()
$(document.body).on 'change', 'input:checkbox.custom.checkbox', (e) ->
  $(e.currentTarget).siblings('span.checkbox').toggleClass 'checked', $(e.currentTarget).is(':checked')
$(document.body).on 'click', '.button.checkbox:not(.dropdown)', (e) ->
  if e.currentTarget == e.target
    $(e.currentTarget).children('span.checkbox').click()

$(document).ajaxSend (e, xhr, options) ->
  xhr.setRequestHeader 'Authorization', 'Basic ' + btoa(pipes.apiToken + ':x') # TODO: cross-browser base64 encoding!

configureMoment = (dateFormat = 'L', timeFormat = 'LT', dow = 1) ->
  moment.lang 'en',
    week:
      dow: dow
    calendar:
      lastDay:  "[Yesterday at] #{timeFormat}"
      sameDay:  "[Today at] #{timeFormat}"
      nextDay:  "[Tomorrow at] #{timeFormat}"
      lastWeek: "[last] dddd [at] #{timeFormat}"
      nextWeek: "dddd [at] #{timeFormat}"
      sameElse: "#{dateFormat}"

configureMoment()

class PipesApp

  models: {}
  views: {}
  steps: {}
  router: null

  foundation: _.throttle (=> $(document).foundation()), 500, leading: false

  # The following is a hack for oauth-type stuff. Step Ids are parsed from document url and if
  # one is found, it is put here so that when a Stepper that contains this step is initialized,
  # it uses this info to initialize itself into a non-default state. Oh the inhumanity!
  pipeStates: {}

  oauth:
    parseState: (oAuthQuery) ->
      oAuthQuery = "" + oAuthQuery
      # Using step id to differentiate between oauth versions hurray
      if oAuthQuery.indexOf('oauth2') > -1
        return pipes.oauth2.parseState(oAuthQuery)
      else if oAuthQuery.indexOf('oauth1') > -1
        return pipes.oauth1.parseState(oAuthQuery)

  oauth2:
    parseState: (oAuthQuery) ->
      return null if not oAuthQuery
      state = oAuthQuery.match(/state=([^?&]+)/)?[1]
      code = oAuthQuery.match(/code=([^?&]+)/)?[1]
      return null if not state or not code # User canceled or otherwise normal panic
      state = state.split(':') # workspaceId, stepId
      workspaceId: +state[0]
      stepId: state[1]
      code: code
    createState: (oAuthStep) ->
      # Create a string, by which we can recover state. Need to preped workspace id, so that toggl
      # (parent frame) knows which view to reopen.
      return (if pipes.workspaceId then "#{pipes.workspaceId}:" else "") + oAuthStep.id

  oauth1:
    parseState: (oAuthQuery) ->
      console.log('oauth1 parseState', 'oAuthQuery:', oAuthQuery)
      return null if not oAuthQuery
      state = oAuthQuery.match(/state=([^?&]+)/)?[1]
      oauth_verifier = oAuthQuery.match(/oauth_verifier=([^?&]+)/)?[1]
      oauth_token = oAuthQuery.match(/oauth_token=([^?&]+)/)?[1]
      console.log('parsed data', state, oauth_verifier, oauth_token)
      return null if not state or not oauth_verifier or not oauth_token # User canceled or otherwise normal panic
      state = state.split(':') # workspaceId, stepId, account_name
      console.log('state', state)
      workspaceId: +state[0]
      stepId: state[1]
      oauth_verifier: oauth_verifier
      oauth_token: oauth_token
      account_name: state[2]
    createState: (oAuthStep) ->
      return (if pipes.workspaceId then "#{pipes.workspaceId}:" else "") + oAuthStep.id + ':' + oAuthStep.account_name

  apiToken: null
  workspaceId: null # Only required when run through toggl and for oauth
  workspacePremium: true # By default, show all
  baseUrl: '/'

  apiUrl: (url) ->
    "#{window.PIPES_API_HOST}/api/v1#{url}"

  redirect: (url) ->
    if window.top != window.self
      window.top.location = url
    else
      window.location.href= url

  windowApi: null

  actions:
    index: ->

      $('#content').html templates['index.html']()

      if not pipes.integrationsListView
        pipes.models.integrations.fetch()
        pipes.integrationsListView = new pipes.views.IntegrationsListView
          el: $('.integrations-list')
          collection: pipes.models.integrations

  initialize: ->

    if window.self == window.top
      $('body').addClass 'no-frame'

    # Need to wait until apiToken & oAuthQuery & workspaceId(optional) & dateFormats(optional) before really doing anything
    initializeApp = _.after 6, =>
      @router = new pipes.AppRouter()
      Backbone.history.start()

    @windowApi = new pipes.WindowApi()
    @windowApi.initialize()

    @windowApi.once 'initialize', =>
      @windowApi.query 'oAuthQuery'
      @windowApi.query 'workspaceId'
      @windowApi.query 'workspacePremium'
      @windowApi.query 'apiToken'
      @windowApi.query 'baseUrl'
      @windowApi.query 'dateFormats'

    @windowApi.once 'oAuthQuery', (@oAuthQuery) =>
      console.log('got', '@oAuthQuery:', @oAuthQuery)
      # Try to parse oauth data from oauth query params
      state = @oauth.parseState oAuthQuery
      if state
        @pipeStates[state.stepId] = state
      initializeApp()

    @windowApi.once 'apiToken', (@apiToken) =>
      initializeApp()

    @windowApi.once 'workspaceId', (@workspaceId) =>
      initializeApp()

    @windowApi.once 'workspacePremium', (@workspacePremium) =>
      initializeApp()

    @windowApi.once 'baseUrl', (@baseUrl) =>
      initializeApp()

    @windowApi.once 'dateFormats', ({dateFormat, timeFormat, dow}) =>
      configureMoment(dateFormat, timeFormat, dow)
      initializeApp()


window.pipes = new PipesApp()

class pipes.AppRouter extends Backbone.Router
  routes:
    '': 'index'

  index: pipes.actions.index
