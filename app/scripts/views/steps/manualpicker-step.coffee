class pipes.steps.ManualPickerStep extends pipes.steps.Step
  ###
  Generic manual-picker-table step for.
  Takes data from sharedData[@inKey]. Assumes each object has key 'id'.
  Constructs an array of selected ids and stores it in sharedData[@outKey]
  ###
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

