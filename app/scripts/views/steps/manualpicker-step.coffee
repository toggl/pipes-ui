class pipes.steps.ManualPickerStep extends pipes.steps.Step
  template: templates['steps/manual-picker.html']
  inKey: 'objects'
  outKey: 'selectedObjects'
  columns: null

  constructor: (options = {}) ->
    super(options)
    @inKey = options.inKey
    @outKey = options.outKey
    @columns = options.columns

  onRun: ->
    console.log('ManualPickerStep.run')
    container = @view.$('.step-container')
    container.html @template
      columns: @columns
      objects: @sharedData[@inKey]
    container.on 'click.manual-picker', '.button.submit', (e) =>
      @pickItems(+$(el).data('id') for el in container.find('input:checked'))

  pickItems: (ids) ->
    @sharedData[@outKey] = ids
    @end()

  onEnd: ->
    @view.$('.step-container').empty().off '.manual-picker'

