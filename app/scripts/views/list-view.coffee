class pipes.views.ListView extends Backbone.View
  # Abstract view for rendering a view for each model in the collection

  createItemView: (model) -> null

  filterFn: (model) -> true # Return false from this to excldue a child view

  initialize: ->
    @listenTo @collection, 'reset add remove', @render
    @childViews = {}

  refreshChildViews: ->
    # Add new views
    @childViews[m.id or m.cid] = @createItemView(m) \
      for m in @collection.models \
      when m.id not of @childViews and m.cid not of @childViews and @filterFn(m)
    # Destroy old views
    for id, view of @childViews
      if not @collection.get(id)
        view.remove()
        view.stopListening()
        delete @childViews[id]

  render: ->
    @refreshChildViews()
    for m in @collection.models
      childView = @childViews[m.id or m.cid]
      continue if not childView
      @$el.append childView.render().$el
    v.setElement(v.el) for k,v of @childViews
    @trigger 'render'
    this
