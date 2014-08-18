class pipes.views.IntegrationsListView extends pipes.views.ListView

  createItemView: (model) ->
    new pipes.views.IntegrationItemView(model: model)

  filterFn: (model) ->
    not pipes.enabledIntegrations.length or model.id in pipes.enabledIntegrations
