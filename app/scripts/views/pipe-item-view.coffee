class pipes.views.PipeItemView extends Backbone.View
  template: templates['pipe-item.html']
  className: 'row pipe'

  stepper: null

  events:
    'click .button.sync': 'startSync'

  initialize: ->
    console.log('initialize', @model)
    @listenTo @model, 'change:status', @refreshStatus
    @cogView = new pipes.views.CogView
      el: @$('.cog-box')
      items: [
        {name: 'destroy', label: "Destroy all relations", fn: ->}
        pipes.views.CogView.divider
        {name: 'unauthorize', label: "Unauthorize", fn: ->}
      ]
    @metaView = new pipes.views.PipeItemMetaView
      el: @$('.meta')
      model: @model
    @stepper = pipes.getStepper(@model.collection.integration, @model, @)
    @stepper.on 'step', @stepChanged

  stepChanged: (step, i, steps) =>
    @refreshSyncButton()

  startSync: =>
    @model.set status: _.extend({}, @model.get('status'), type: 'in_progress', message: "In progress")
    @stepper.endCurrentStep() if @stepper.current.default

  render: =>
    @$el.html @template model: @model
    @cogView.setElement @$('.cog-box')
    @cogView.render()
    @metaView.setElement @$('.meta')
    @metaView.render()
    @$el.foundation()
    @refreshSyncButton()
    @

  refreshSyncButton: ->
    # Allow sync button only in default step if status = ok
    @$('.button.sync')
      .attr 'disabled', not @stepper.current.default or @model.get('status').type != 'success'
      .children('.button-label').text if @stepper.current.default and @model.get('status').type == 'success' then "Sync now" else "Syncing..."

  refreshStatus: ->
    @metaView.render()
    @refreshSyncButton()


class pipes.views.PipeItemMetaView extends Backbone.View
  template: templates['pipe-item-meta.html']

  render: =>
    @$el.html @template model: @model
    @


pipes.getStepper  = (integration, pipe, pipeView) ->
  console.log('pipes.getStepper', 'integration:', integration, 'pipe:', pipe, 'pipeView:', pipeView)
  switch integration.id
    when 'basecamp'
      switch pipe.id
        when 'users'
          return new pipes.steps.Stepper
            view: pipeView
            steps: [
              new pipes.steps.IdleState(default: true)
              new pipes.steps.OAuthStep()
              new pipes.steps.AccountSelectorStep()
              new pipes.steps.DataPollStep(url: '', key: 'users')
              new pipes.steps.ManualPickerStep(
                inKey: 'users',
                outKey: 'selectedUsers'
                columns: [{key: 'name', label: "Name"}, {key: 'email', label: "E-mail"}]
              )
              new pipes.steps.DataSubmitStep(url: '', key: 'selectedUsers')
            ]
        else
          throw "Integration #{integration.id} doesn't have logic for pipe #{pipe.id}"
    else
      throw "Integration #{integration.id} doesn't have any pipes defined"

