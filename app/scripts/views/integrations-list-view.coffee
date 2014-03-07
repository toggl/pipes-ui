class pipes.views.IntegrationsListView extends pipes.views.ListView
  createItemView: (model) ->
    new pipes.views.IntegrationItemView(model: model)
