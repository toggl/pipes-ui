pipes.integrationStepperFactory = (integration, configurationView) ->
  switch integration.get('id')
    when 'basecamp', 'teamweek', 'asana'
      return new pipes.steps.Stepper
        view: configurationView
        steps: [
          new pipes.steps.NoOpStep(default: true)
          new pipes.steps.OAuth2Step(integration: integration, view: configurationView)
        ]
    when 'freshbooks'
      return new pipes.steps.Stepper
        view: configurationView
        steps: [
          new pipes.steps.NoOpStep(default: true)
          new pipes.steps.OAuth1Step(
            integration: integration
            view: configurationView
            title: "Please enter your Freshbooks account name:"
            inputSuffix: ".freshbooks.com"
          )
        ]
    else
      throw "Integration #{integration.id} doesn't have any configuration steps defined"
