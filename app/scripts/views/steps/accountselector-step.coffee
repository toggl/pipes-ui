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

  callback: (response, step) ->
    if not response?.accounts?.length?
      throw 'OMG'
      # TODO
    if response.accounts.length > 1
      @displayList response.accounts
      return false # Don't auto-end()
    else
      @selectAccount response.accounts[0].id

  onEnd: ->
    @getContainer().empty().off '.account-selection'

  displayList: (accounts) ->
    @getContainer().html @listTemplate accounts: accounts
    @getContainer().on 'click.account-selection', '.button.select-account', (e) =>
      @getContainer().find('.button.select-account').attr 'disabled', true
      @selectAccount $(e.currentTarget).data('id')

  selectAccount: (@accountId) ->
    @sharedData[@outKey] = @accountId
    @end()