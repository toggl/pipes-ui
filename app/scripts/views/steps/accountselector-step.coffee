class pipes.steps.AccountSelectorStep extends pipes.steps.Step
  ###
  An all-in-one account selector step.
  Fetches accounts from the given url, displayes them in a list and
  stores the selected account's id in @sharedData.accountId
  ###

  listTemplate: templates['steps/account-selector.html']
  accounts: null
  url: null

  onRun: ->
    console.log('AccountSelectorStep.run')
    @accounts = [
      {id: 1, name: "Account 1"}
      {id: 2, name: "Account 2"}
      {id: 3, name: "Account 3"}
    ]
    @displayList()
    return
    $.get @url,
      success: ({@accounts}) =>
        if not @accounts.length?
          throw 'OMG'
          # TODO
        if @accounts.length > 1
          @displayList @accounts
        else
          @selectAccount @accounts[0].id

  onEnd: ->
    @view.$('.step-container').empty().off '.account-selection'

  displayList: ->
    container = @view.$('.step-container')
    container.html @listTemplate accounts: @accounts
    container.on 'click.account-selection', '.button.select-account', (e) =>
      container.find('.button.select-account').attr 'disabled', true
      @selectAccount $(e.currentTarget).data('id')

  selectAccount: (@accountId) ->
    @sharedData.accountId = @accountId
    @end()