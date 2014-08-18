class pipes.views.PipesListView extends pipes.views.ListView

  createItemView: (model) ->
    new pipes.views.PipeItemView(model: model)

  filterFn: (model) ->
    not pipes.enabledPipes.length or "#{model.collection.integration.id}.#{model.id}" in pipes.enabledPipes
