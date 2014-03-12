class pipes.steps.AccountSelectorStep extends pipes.steps.DataPollStep
  ###
  An all-in-one account selector step.
  Polls accounts from the given url, displayes them in a list and
  stores the selected account's id in @sharedData[@outKey]
  ###

  listTemplate: templates['steps/account-selector.html']
  url: null

  constructor: (options = {}) ->
    super(options)
    @outKey = options.outKey or 'accountId'

  initialize: (options) ->
    super(options)
    @url = @view.model.collection.integration.accountsUrl()
    @skip = !!view.model.get('configured')

  callback: (response, step) ->
    if not response?.accounts?.length?
      throw 'OMG'
      # TODO
    if response.accounts.length > 1
      @displayList response.accounts
    else
      @selectAccount response.accounts[0].id

  onEnd: ->
    @view.$('.step-container').empty().off '.account-selection'

  displayList: (accounts) ->
    container = @view.$('.step-container')
    container.html @listTemplate accounts: accounts
    container.on 'click.account-selection', '.button.select-account', (e) =>
      container.find('.button.select-account').attr 'disabled', true
      @selectAccount $(e.currentTarget).data('id')

  selectAccount: (@accountId) ->
    @sharedData[@outKey] = @accountId
    @end()