class pipes.views.PipeItemView extends Backbone.View
  template: templates['pipe-item.html']
  className: 'row pipe'

  initialize: ->
    @listenTo @model, 'change', @render

  render: ->
    @$el.html @template model: @model
    @$el.foundation()
    @
