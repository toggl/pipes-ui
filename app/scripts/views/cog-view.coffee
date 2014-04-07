class pipes.views.CogView extends Backbone.View

  @divider = {name: '', label: '', fn: null, divider: true}

  template: templates['cog-box.html']
  events:
    'click li a:not(.disabled), li button:not(.disabled)': 'clickItem'

  initialize: (options) ->
    @_id = "cog-#{Math.random()*999999999 | 0}" # Used to link together menu & button
    throw new Error("'items' is required parameter for CogView.initialize") if not options.items
    if not options.items[0]?.items? # No groups: simulate 1 untitled group
      @items = [{title: null, items: options.items}]
    else
      @items = options.items

  close: ->
    @$('[data-dropdown].open').click()

  clickItem: (e) ->
    e.preventDefault()
    data = $(e.currentTarget).data()
    for group in @items
       fn = _.find(group.items, (item) -> item.name == data.name).fn
       if fn
         close = fn(data.name, $(e.currentTarget)) # Fire callback fn
         break
    @trigger 'select', data.name
    @close() unless close == false

  render: ->
    @$el.html @template
      _id: @_id
      groups: @items
    @$el.toggle @$('li:not(.title):not(.divider)').length > 0
