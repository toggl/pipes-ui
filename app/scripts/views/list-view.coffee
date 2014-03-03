class pipes.views.ListView extends Backbone.View
  # Abstract view for rendering a view for each model in the collection

  itemViewClass: -> null

  initialize: ->
    @listenTo @collection, 'reset add remove', @render
    @childViews = {}

  refreshChildViews: ->
    # Add new views
    @childViews[m.id or m.cid] = new (@itemViewClass())(model: m) \
      for m in @collection.models \
      when m.id not of @childViews and m.cid not of @childViews
    # Destroy old views
    for id, view of @childViews
      if not @collection.get(id)
        view.remove()
        delete @childViews[id]

  render: ->
    @refreshChildViews()
    @$el.append @childViews[m.id or m.cid].render().$el for m in @collection.models
    @
