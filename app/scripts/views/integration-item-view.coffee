class pipes.views.IntegrationItemView extends Backbone.View
  template: templates['integration-item.html']
  className: 'row integration'
  pipesListViewClass: -> pipes.views.PipesListView

  initialize: ->
    @listenTo @model, 'change', @render
    @cogView = new pipes.views.CogView
      items: [
        {
          name: 'deauthorize'
          label: "Delete authorization"
          fn: @deauthorize
          skip: =>
            not @model.get('authorized')
        }
      ]

  render: ->
    @$el.html @template model: @model
    @cogView.setElement @$('.integration-cog')
    @cogView.render()
    @pipesList = new (@pipesListViewClass())(collection: @model.getPipes()) if not @pipesList
    @pipesList.setElement(@$('.pipes-list'))
    @pipesList.render()
    @$el.foundation()
    this

  deauthorize: =>
    @model.deleteAuthorization()
