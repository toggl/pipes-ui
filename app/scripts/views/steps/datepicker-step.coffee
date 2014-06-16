class pipes.steps.DatePickerStep extends pipes.steps.Step

  template: templates['steps/datepicker.html']
  outKey: 'date'
  title: "Select date"

  constructor: (options = {}) ->
    super(options)
    @outKey = options.outKey
    @title = options.title if options.title

  onRun: ->
    @render()

  onEnd: ->
    @clear()

  clear: ->
    @getContainer().empty().off '.datepicker'
    @datePickerPopdown?.remove()

  render: ->
    @clear()
    container = @getContainer()
    container.html @template {@title}
    container.off '.datepicker'
    container.on 'click.datepicker', '.button.submit', @clickSubmit
    now = moment()
    @datePickerPopdown = new pipes.DatePickerPopdown
      input: container.find('input.date')
      autoOpen: true
      value: new Date()
      onRenderCell: (el, date) ->
        disabled: moment(date).isAfter(now, 'day') or moment(date).isBefore(now.clone().subtract(3, 'months'))

  clickSubmit: (e) =>
    e.preventDefault()
    @sharedData[@outKey] = moment(@datePickerPopdown.getInputValue()).format("YYYY-MM-DD")
    @end()
