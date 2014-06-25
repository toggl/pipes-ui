class pipes.views.IntegrationItemView extends Backbone.View
  template: templates['integration-item.html']
  pipesListViewClass: -> pipes.views.PipesListView
  className: 'row integration'

  initialize: ->
    @listenTo @model, 'change', @render
    @listenTo @model, 'change:authorized', @authorizedChanged
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

  authorizedChanged: (model, authorized) =>
    # Hackish way to scroll down when coming back from oauth
    setTimeout (=> pipes.windowApi.sendMessage("scrollTo:#{@$el.offset().top}")), 500 if authorized

  render: ->
    @$el.html @template
      model: @model
      pipeTitles: @model.getPipes().map((p) -> p.get('name')).join(' / ')
      showPipeTitles: not @model.get('authorized')
    @cogView.setElement @$('.integration-cog')
    @cogView.render()
    if @model.get('authorized')
      if @configurationView
        @configurationView.remove()
        @configurationView = null
      @pipesListView = new (@pipesListViewClass())(collection: @model.getPipes()) if not @pipesListView
      @pipesListView.setElement(@$('.pipes-list'))
      @pipesListView.render()
    else
      if @pipesListView
        @pipesListView.remove()
        @pipesListView = null
      @configurationView = new pipes.IntegrationConfigurationView({@model, el: @$('.integration-configuration')}) if not @configurationView
      @configurationView.setElement(@$('.integration-configuration'))
      @configurationView.render()
    this

  deauthorize: =>
    @model.deleteAuthorization()
