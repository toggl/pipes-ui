class pipes.views.PipeItemView extends Backbone.View
  template: templates['pipe-item.html']
  className: 'row pipe'

  initialize: ->
    @listenTo @model, 'change', @render
    @cog = new pipes.views.CogView
      el: @$('.cog-box')
      items: [
        {name: 'destroy', label: "Destroy all relations", fn: ->}
        pipes.views.CogView.divider
        {name: 'unauthorize', label: "Unauthorize", fn: ->}
      ]

  render: ->
    @$el.html @template model: @model
    @cog.setElement @$('.cog-box')
    @cog.render()
    @$el.foundation()
    @
