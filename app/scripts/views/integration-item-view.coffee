class pipes.views.IntegrationItemView extends Backbone.View
  template: templates['integration-item.html']
  className: 'row integration'
  pipesListViewClass: -> pipes.views.PipesListView

  initialize: ->
    @listenTo @model, 'change', @render

  render: ->
    @$el.html @template model: @model
    @pipesList = new (@pipesListViewClass())(collection: @model.getPipes()) if not @pipesList
    @pipesList.setElement(@$('.pipes-list'))
    @pipesList.render()
    @
