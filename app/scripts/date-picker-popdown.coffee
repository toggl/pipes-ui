
class pipes.DatePickerPopdown extends Backbone.View
  className: 'popdown right'
  template: templates['datepicker-popdown.html']

  events:
    'click .button-apply': 'clickApply'
    'click .button-close': 'clickClose'

  initialValue: ''

  initialize: ({input, @autoOpen, value, @onRenderCell}) ->
    @$input = $(input)
    if @autoOpen
      @$input.on 'focus.datePickerPopdown', @open
    if value
      @$input.val @serializeValue(value)

  remove: ->
    super()
    @$input.off '.datePickerPopdown'

  open: =>
    @initialValue = @$input.val()
    $(document).on 'click.datePickerPopdown', @clickDocument
    @$input.on 'keyup.datePickerPopdown', @inputChange
    @render()

  close: (reset = false) =>
    $(document).off 'click.datePickerPopdown'
    @$input.off 'keyup.datePickerPopdown'
    if reset
      @restoreValue()
    else
      @$input.val @serializeValue(@getDatePickerValue()) # Final overwrite to get rid of invalid data
    @$el.detach()

  render: ->
    console.log('render')
    @$el.html @template()
    $('body').append @$el
    @$('.datepicker-container').DatePicker
      mode: 'single'
      inline: true
      date: @parseValue @$input.val()
      allowNotInMonth: true
      starts: pipes.dateSettings.dow
      onChange: @datePickerChange
      onRenderCell: @onRenderCell
    @$el.position
      my: 'right top'
      at: 'right bottom'
      of: @$input

  clickApply: (e) =>
    @close()

  clickDocument: (e) =>
    return if e.target == @$input.get(0) or $(e.target).closest(@$el).length
    @close()

  clickClose: (e) =>
    @close(true)

  inputChange: (e) =>
    @$('.datepicker-container').DatePickerSetDate @getInputValue(), true

  datePickerChange: (e) =>
    @$input.val @serializeValue(@getDatePickerValue())

  restoreValue: ->
    @$input.val @initialValue

  getInputValue: ->
    @parseValue @$input.val()

  getDatePickerValue: ->
    @$('.datepicker-container').DatePickerGetDate()[0]

  serializeValue: (date) ->
    moment(date).format(pipes.dateSettings.dateFormat)

  parseValue: (str) ->
    moment(str, pipes.dateSettings.dateFormat).toDate()
