{View} = require 'atom-space-pen-views'
$ = require 'jquery'
SubAtom = require 'sub-atom'

module.exports =
class MultiWrapGuideView extends View
  columns: []                 # Current column widths.
  configSubs: null            # SubAtom object for config event handlers.
  currentCursorColumn: null   # Current mouse position in column width.
  editor: null                # Attached editor.
  editorElement: null         # Attached editor element.
  emitter: null               # Package emitter object.
  enabled: true               # True iff guide lines are enabled.
  linesView: null             # Attached lines view.
  locked: false               # True iff guide lines are locked.
  subs: null                  # SubAtom object for general event handlers.
  visible: true               # True iff guide lines are currently visible.

  @content: ->
    @div class: 'multi-wrap-guide-view'

  # Public: Creates new wrap guide view for given editor.
  initialize: (@editor, @emitter, @views) ->
    @subs = new SubAtom
    @locked = atom.config.get 'multi-wrap-guide.locked'
    @enabled = atom.config.get 'multi-wrap-guide.enabled'
    @editorElement = atom.views.getView editor
    @attach()
    @handleEvents()
    @columns = @getColumns()
    @showGuides()
    this

  # Public: Destroys all wrap guides.
  destroy: ->
    @linesView.find('div.multi-wrap-guide-view').empty().remove()
    @subs?.dispose()
    @subs = null if @subs
    @configSubs?.dispose()
    @configSubs = null if @configSubs

  # Private: Returns true for only the one of the existing MultiWrapGuide objects.
  isMasterView: ->
    masterId = parseInt(Object.keys(@views).sort((a, b) -> a - b)[0])
    @editor.id is masterId

  # Private: Returns left offset of mouse curosr from a given mouse event.
  leftOffsetFromMouseEvent: (e) ->
    {clientX} = event
    linesClientRect = @linesView[0].getBoundingClientRect()
    targetLeft = clientX - linesClientRect.left
    targetLeft

  # Private: Returns column number of mouse cursor from a given mouse event.
  columnFromMouseEvent: (e) ->
    targetLeft = @leftOffsetFromMouseEvent(e) + @editor.getScrollLeft()
    left = 0
    column = 0
    charWidth = @editorElement.getDefaultCharacterWidth()
    while targetLeft > left + (charWidth / 2)
      left += charWidth
      column += 1
    column

  # Private: Returns the column at the given page x position in piexls.
  columnFromPostiionX: (x) ->
    x += @editor.getScrollLeft()
    charWidth = @editorElement.getDefaultCharacterWidth()
    leftSide = (x // charWidth) * charWidth
    rightSide = (x // charWidth + 1) * charWidth
    if Math.abs(x - leftSide) < Math.abs(x - rightSide)
      column = leftSide // charWidth
    else
      column = rightSide // charWidth
    column

  # Private: Attach wrap guides to editor.
  attach: ->
    @linesView = $(@editorElement.rootElement.querySelector 'div.lines')
    @linesView.append this

  # Private: Handles did-toggle events.
  onDidToggle: ->
    @enabled = not @enabled
    @showGuides()

  # Private: Handles did-toggle-lock events.
  onDidToggleLock: ->
    @locked = not @locked
    if @locked
      @lock()
    else
      @unlock()
    @showGuides()

  # Private: Handles did-change-guides events.
  onDidChangeGuides: (columns, scope) ->
    # active editor initiated create/remove, so only inactive editors need updating
    return if atom.workspace.getActiveTextEditor() is @editor
    # guide columns are specific to grammars, so only update for the current scope
    return unless "#{@editor.getRootScopeDescriptor()}" is "#{scope}"
    @columns = columns
    @showGuides()

  # Private: Sets up wrap guide event and command handlers.
  handleEvents: ->
    @configSubs = @handleConfigEvents()

    showGuidesCallback = => @showGuides()
    @subs.add atom.config.onDidChange 'editor.fontSize', ->
      # setTimeout() to wait for @editorElement.getDefaultCharacterWidth() measurement to happen
      setTimeout showGuidesCallback, 0
    @subs.add @editor.onDidChangeScrollLeft -> showGuidesCallback()
    @subs.add @editor.onDidChangePath -> showGuidesCallback()
    @subs.add @editorElement.onDidAttach =>
      @attach()  # TODO: Do we *always* need to attach() here, or only sometimes?
      showGuidesCallback()
    @subs.add @editor.onDidChangeGrammar =>
      @configSubs.dispose()
      @configSubs = @handleConfigEvents()
      @columns = @getColumns()
      showGuidesCallback()

    @subs.add @editorElement, 'mousemove', (e) =>
      @currentCursorColumn = @columnFromMouseEvent e

    @subs.add atom.commands.add 'atom-workspace',
      'multi-wrap-guide:create-guide': => @createGuide @currentCursorColumn
    @subs.add atom.commands.add 'atom-workspace',
      'multi-wrap-guide:remove-guide': => @removeGuide @currentCursorColumn

    @emitter.on 'did-toggle-lock', => @onDidToggleLock()
    @emitter.on 'did-toggle', => @onDidToggle()
    @emitter.on 'did-change-guides', (data) =>
      {columns, scope} = data
      @onDidChangeGuides columns, scope

  # Private: Sets up wrap guide configuration change event handlers.
  handleConfigEvents: ->
    updateGuidesCallback = =>
      @columns = @getColumns()
      @showGuides()
    subs = new SubAtom
    scope = @editor.getRootScopeDescriptor()
    scopedSubscribe = (key, callback) ->
      subs.add atom.config.onDidChange key, scope: scope, callback
    scopedSubscribe 'editor.preferredLineLength', updateGuidesCallback
    scopedSubscribe 'multi-wrap-guide.columns', updateGuidesCallback
    subs.add atom.config.onDidChange 'multi-wrap-guide.locked', updateGuidesCallback
    subs.add atom.config.onDidChange 'multi-wrap-guide.enabled', updateGuidesCallback
    subs

  # Private: Creates a new JQuery DOM element with given type and classes.
  createElement: (type, classes...) ->
    element = $(document.createElement type)
    for c in classes
      element.addClass c
    element

  # Private: Adds a new guide the given column, if one doesn't already exist.
  createGuide: (column) ->
    return unless atom.workspace.getActiveTextEditor() is @editor
    i = @columns.indexOf(column)
    if i is -1
      @columns.push column
    @saveColumns()
    @showGuides()
    @didChangeGuides()

  # Private: Emits did-change-guides signal.
  didChangeGuides: ->
    @emitter.emit 'did-change-guides',
      columns: @columns
      scope: @editor.getRootScopeDescriptor()

  # Private: Removes the guide at or near the given column, if one exists.
  removeGuide: (column) ->
    return unless atom.workspace.getActiveTextEditor() is @editor
    for i in [column, column - 1, column + 1, column - 2, column + 2]
      index = @columns.indexOf(i)
      if index > -1
        @columns.splice(index, 1)
        break
    @saveColumns()
    @showGuides()
    @didChangeGuides()

  # Private: Locks guides so they can't be dragged.
  lock: ->
    @locked = true
    for guide in @children()
      guide.classList.remove 'draggable'

  # Private: Unlocks guides so they can be dragged.
  unlock: ->
    @locked = false
    for guide in @children()
      guide.classList.add 'draggable'

  # Private: Mouse down event handler, initiates guide dragging.
  mouseDown: (e) =>
    return if @locked
    return if e.button
    guide = $(e.data[0])
    guide.addClass 'drag'
    guide.mouseup guide, @mouseUp
    guide.mousemove guide, @mouseMove
    guide.mouseleave guide, @mouseLeave
    false

  # Private: Mouse move event handler, updates position and tip text.
  mouseMove: (e) =>
    guide = $(e.data[0])
    targetLeft = @leftOffsetFromMouseEvent e
    guide.css 'left', "#{targetLeft}px"
    @setTip guide
    false

  # Private: Mouse up event handler, drops guide at selected column.
  mouseUp: (e) =>
    guide = $(e.data[0])
    @dragEnd guide
    @columns = (parseInt(tip.textContent) for tip in @find 'div.multi-wrap-guide-tip')
    @saveColumns()
    @didChangeGuides()

  # Private: Saves current columns to config if auto save enabled.
  saveColumns: ->
    @columns = $.unique(@columns.sort (a, b) -> a - b)
    scope = @editor.getRootScopeDescriptor()
    scopeSelector = @getRootScopeSelector()
    return unless @doAutoSave()
    atom.config.set 'multi-wrap-guide.columns', @columns, scopeSelector: scopeSelector

  # Private: Mouse leave event handler, cancels guide dragging.
  mouseLeave: (e) =>
    guide = $(e.data[0])
    @dragEnd guide
    @showGuides()

  # Private: Ends guide dragging for the given guide.
  dragEnd: (guide) ->
    guide.unbind 'mouseleave'
    guide.unbind 'mousemove'
    guide.unbind 'up'
    guide.removeClass 'drag'

  # Private: Sets the current column location of the given guide.
  # Pre-condition: The tip element must be appended to the guide.
  setColumn: (guide, column) ->
    columnWidth = (@editorElement.getDefaultCharacterWidth() * column) - @editor.getScrollLeft()
    guide.css 'left', "#{columnWidth}px"
    @setTipColumn guide, column

  # Private: Sets the tip text based on the guide's current position.
  # Pre-condition: The tip element must be appended to the guide.
  setTip: (guide) ->
    column = @columnFromPostiionX parseInt(guide.css 'left')
    @setTipColumn guide, column

  # Private: Sets the tip text to be the given column.
  # Pre-condition: The tip element must be appended to the guide.
  setTipColumn: (guide, column) ->
    guide.prop 'title', column
    guide.find('div.multi-wrap-guide-tip').text column

  # Private: Returns a `scopeSelector` for `atom.config.set()`; compare to
  # `editor.getRootScopeDescriptor()` that returns a `scope` descriptor for `atom.config.get()`.
  getRootScopeSelector: ->
    ".#{@editor.getGrammar().scopeName}"

  # Private: Returns true iff autosave should occur.
  doAutoSave: ->
    atom.config.get 'multi-wrap-guide.autoSaveChanges'

  # Private: Gets current columns configuration value.
  getColumns: ->
    scope = @editor.getRootScopeDescriptor()
    defaultColumns = [atom.config.get 'editor.preferredLineLength', scope: scope]
    customColumns = atom.config.get 'multi-wrap-guide.columns', scope: scope
    if customColumns.length > 0 then customColumns else defaultColumns

  # Private: Redraws current guides.
  showGuides: =>
    return unless @editorElement.getDefaultCharacterWidth()
    @empty()
    return unless @enabled
    for column in @columns
      guide = @createElement 'div', 'multi-wrap-guide'
      guide.addClass 'draggable' unless @locked
      tip = @createElement 'div', 'multi-wrap-guide-tip'
      line = @createElement 'div', 'multi-wrap-guide-line'
      line.append tip
      guide.append line
      guide.mousedown guide, @mouseDown
      @setColumn guide, column  # must be called after appending tip
      @append guide
