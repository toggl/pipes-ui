class pipes.views.ListView extends Backbone.View
  # Abstract view for rendering a view for each model in the collection

  createItemView: (model) -> null

  initialize: ->
    @listenTo @collection, 'reset add remove', @render
    @childViews = {}

  refreshChildViews: ->
    # Add new views
    @childViews[m.id or m.cid] = @createItemView(m) \
      for m in @collection.models \
      when m.id not of @childViews and m.cid not of @childViews
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
      @$el.append childView.render().$el
      childView.trigger 'show'
    v.setElement(v.el) for k,v of @childViews
    this
