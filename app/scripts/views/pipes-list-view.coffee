class pipes.views.PipesListView extends pipes.views.ListView
  createItemView: (model) ->
    new pipes.views.PipeItemView(model: model)
