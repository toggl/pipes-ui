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
    container = @view.$('.step-container')
    container.html @template
      columns: @columns
      objects: @sharedData[@inKey]
    container.on 'change.manual-picker', 'thead input:checkbox', @clickMainCheckbox
    container.on 'change.manual-picker', 'tbody input:checkbox', @clickCheckbox
    container.on 'click.manual-picker', '.button.submit', @clickSubmit
    container.on 'keyup.manual-picker', 'input.filter', _.throttle(@filterObjects, 400, leading: false)
    @refreshSubmitButton()
    @refreshMainCheckbox()

  onEnd: ->
    @view.$('.step-container').empty().off '.manual-picker'

  clickMainCheckbox: (e, extra = {}) =>
    return if extra?.manualPickerIgnore
    $tbody = @view.$('.step-container tbody')
    $unchecked = $tbody.find('input:checkbox:visible:not(:checked)')
    if $(e.currentTarget).prop 'checked'
      $unchecked.prop('checked', true).trigger 'change', [manualPickerIgnore: true]
    else
      $tbody.find('input:checkbox:visible').prop('checked', false).trigger 'change', [manualPickerIgnore: true]
    @refreshSubmitButton()
    @refreshMainCheckbox()

  clickCheckbox: (e, extra = null) =>
    return if extra?.manualPickerIgnore
    @refreshSubmitButton()
    @refreshMainCheckbox()

  refreshSubmitButton: ->
    @view.$('.step-container .button.submit').attr 'disabled',
      @view.$('.step-container tbody input:checkbox:visible:checked').length == 0

  refreshMainCheckbox: ->
    @view.$('.step-container thead input:checkbox:visible').prop('checked',
      @view.$('.step-container tbody input:checkbox:visible:not(:checked)').length == 0)
      .trigger 'change', [manualPickerIgnore: true]

  filterObjects: =>
    word = @view.$('.step-container input.filter').val().toLowerCase()
    objects = @sharedData[@inKey]
    filteredColumns = (col.key for col in @columns when !!col.filter)

    rows = @view.$('.step-container tbody>tr')
    rows.filter(':visible').hide()

    rows = (id: $(row).data('id'), el: $(row) for row in rows)
    console.log('filter', rows, word, filteredColumns)

    filteredIds = _.pluck(_.filter(objects, (obj) ->
      true in ( ('' + obj[col]).toLowerCase().indexOf(word) != -1 or not word for col in filteredColumns)
    ), 'id')

    filteredRows= _.filter rows, (row) -> row.id in filteredIds

    row.el.show() for row in filteredRows

  clickSubmit: (e) =>
    @submitItems(+$(el).data('id') for el in @view.$('.step-container tbody input:checked'))

  submitItems: (ids) ->
    @sharedData[@outKey] = ids
    @end()

