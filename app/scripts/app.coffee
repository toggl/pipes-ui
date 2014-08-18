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
  xhr.setRequestHeader 'Authorization', 'Basic ' + btoa(pipes.apiToken + ':x')

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
  dateSettings: null

  foundation: _.throttle (=> $(document).foundation()), 500, leading: false

  # The following is a hack for oauth-type stuff. Step Ids are parsed from document url and if
  # one is found, it is put here so that when a Stepper that contains this step is initialized,
  # it uses this info to initialize itself into a non-default state. Oh the inhumanity!
  stepStates: {}

  oauth: # TODO: Refactor oauth stuff
    parseState: (oAuthQuery) ->
      oAuthQuery = "" + oAuthQuery
      # Using step id to differentiate between oauth versions hurray
      if oAuthQuery.indexOf('oauth2') > -1
        return pipes.oauth2.parseState(oAuthQuery)
      else if oAuthQuery.indexOf('oauth1') > -1
        return pipes.oauth1.parseState(oAuthQuery)

  oauth2: # TODO: Refactor oauth stuff
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

  oauth1: # TODO: Refactor oauth stuff
    parseState: (oAuthQuery) ->
      return null if not oAuthQuery
      state = oAuthQuery.match(/state=([^?&]+)/)?[1]
      oauth_verifier = oAuthQuery.match(/oauth_verifier=([^?&]+)/)?[1]
      oauth_token = oAuthQuery.match(/oauth_token=([^?&]+)/)?[1]
      return null if not state or not oauth_verifier or not oauth_token # User canceled or otherwise normal panic
      state = state.split(':') # workspaceId, stepId, account_name
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

  commands:
    startAuthorization: (integrationId) ->
      pipes.integrationsListView.childViews[integrationId]?.configurationView.startAuthorization()
    startSync: (pipeId) ->
      [integrationId, pipeId] = pipeId.split('.')
      pipes.integrationsListView.childViews[integrationId]?.pipesListView.childViews[pipeId]?.startSync()

  actions:
    index: ->

      $('#content').html templates['index.html']()

      if not pipes.integrationsListView
        pipes.models.integrations.fetch()
        pipes.integrationsListView = new pipes.views.IntegrationsListView
          el: $('.integrations-list')
          collection: pipes.models.integrations
        pipes.integrationsListView.once 'render', -> pipes.windowApi.sendMessage 'initialized'

  initialize: ->

    if window.self == window.top
      $('body').addClass 'no-frame'

    initializeApp = (options) =>

      @apiToken = options.apiToken
      @workspaceId = options.workspaceId
      @workspacePremium = options.workspacePremium
      @baseUrl = options.baseUrl
      @dateSettings = options.date
      @enabledPipes = options.enabledPipes or []
      @enabledIntegrations = _.uniq _.map(@enabledPipes or [], (id) -> id.split('.')[0])
      @stepStates = options.stepStates or {}
      configureMoment(options.date.dateFormat, options.date.timeFormat, options.date.dow)
      state = @oauth.parseState options.oAuthQuery
      if state
        @stepStates[state.stepId] = state

      @router = new pipes.AppRouter()
      Backbone.history.start()

    @windowApi = new pipes.WindowApi()
    @windowApi.initialize()

    @windowApi.once 'initialize', initializeApp # Init call from parent frame


window.pipes = new PipesApp()

class pipes.AppRouter extends Backbone.Router
  routes:
    '': 'index'

  index: pipes.actions.index
