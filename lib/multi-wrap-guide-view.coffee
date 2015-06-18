{View} = require 'atom-space-pen-views'
$ = require 'jquery'
SubAtom = require 'sub-atom'

module.exports =
class MultiWrapGuideView extends View
  columns: []                 # Current column positions.
  configSubs: null            # SubAtom object for config event handlers.
  currentCursorColumn: null   # Current mouse position in column position.
  currentCursorRow: null      # Current mouse position in row position.
  editor: null                # Attached editor.
  editorElement: null         # Attached editor element.
  emitter: null               # Package emitter object.
  enabled: true               # True iff guide lines are enabled.
  linesView: null             # Attached lines view.
  locked: false               # True iff guide lines are locked.
  rows: []                    # Current row positions.
  subs: null                  # SubAtom object for general event handlers.
  visible: true               # True iff guide lines are currently visible.

  @content: ->
    @div class: 'multi-wrap-guide-view'

  # Public: Creates new wrap guide view for given editor.
  initialize: (@editor, @emitter) ->
    @subs = new SubAtom
    @locked = atom.config.get 'multi-wrap-guide.locked'
    @enabled = atom.config.get 'multi-wrap-guide.enabled'
    @editorElement = atom.views.getView editor
    @attach()
    @handleEvents()
    @columns = @getColumns()
    @rows = @getRows()
    @redraw()
    this

  # Public: Destroys all wrap guides.
  destroy: ->
    @linesView.find('div.multi-wrap-guide-view').empty().remove()
    @subs?.dispose()
    @subs = null
    @configSubs?.dispose()
    @configSubs = null

  # Private: Returns [left, top] offsets of mouse curosr from a given mouse event.
  offsetFromMouseEvent: (e) ->
    {clientX, clientY} = event
    linesClientRect = @linesView[0].getBoundingClientRect()
    left = clientX - linesClientRect.left
    top = clientY - linesClientRect.top
    [left, top]

  # Private: Returns [column, row] numbers of mouse cursor from a given mouse event.
  positionFromMouseEvent: (e) ->
    [offsetLeft, offsetTop] = @offsetFromMouseEvent(e)
    targetLeft = offsetLeft + @editor.getScrollLeft()
    targetTop = offsetTop + @editor.getScrollTop()
    left = 0
    column = 0
    charWidth = @editorElement.getDefaultCharacterWidth()
    while targetLeft > left + (charWidth / 2)
      left += charWidth
      column += 1
    top = 0
    row = 0
    lineHeight = @editor.getLineHeightInPixels()
    while targetTop > top + (lineHeight / 2)
      top += lineHeight
      row += 1
    [column, row]

  # Private: Attach wrap guides to editor.
  attach: ->
    @linesView = $(@editorElement.rootElement.querySelector 'div.lines')
    @linesView.append this

  # Private: Sets up wrap guide event and command handlers.
  handleEvents: ->
    @configSubs = @handleConfigEvents()

    redrawCallback = =>
      @redraw()
    @subs.add atom.config.onDidChange 'editor.fontSize', ->
      # setTimeout() to wait for @editorElement.getDefaultCharacterWidth() measurement to happen
      setTimeout redrawCallback, 0
    @subs.add @editor.onDidChangeScrollLeft -> redrawCallback()
    @subs.add @editor.onDidChangeScrollTop -> redrawCallback()
    @subs.add @editor.onDidChangePath -> redrawCallback()
    @subs.add @editor.onDidChangeSoftWrapped -> redrawCallback()
    @subs.add @editorElement.onDidAttach =>
      @attach()
      redrawCallback()
    @subs.add @editor.onDidChangeGrammar =>
      @configSubs.dispose()
      @configSubs = @handleConfigEvents()
      @columns = @getColumns()
      @rows = @getRows()
      redrawCallback()

    ## TODO: When code is folded/unfolded, we need to update horizontal guides.
    ##
    ## Possible events to trigger off of:
    ##   - onDid[Add/Remove]Decoration: happens too often. Best possible solution?
    ##   - onDidUpdateMarkers: happens way too often.
    ##   - onDidChange w/ filter for events we care about: happens waaaaaay too often!
    ##
    ## Using any of these events requires debounce/threshold logic :(
    ##
    ## Workaround: Redraw only onDidChangeScrollTop.
    ##
    # handleUpdateMarkers = ->
    #   redrawCallback()
    # @subs.add @editor.onDidAddDecoration _.debounce(handleUpdateMarkers, 500)
    # @subs.add @editor.onDidRemoveDecoration _.debounce(handleUpdateMarkers, 500)

    @subs.add @editorElement, 'mousemove', (e) =>
      [col, row] = @positionFromMouseEvent e
      @currentCursorColumn = col
      @currentCursorRow = row

    @subs.add atom.commands.add 'atom-workspace',
      'multi-wrap-guide:create-vertical-guide': => @createVerticalGuide @currentCursorColumn
    @subs.add atom.commands.add 'atom-workspace',
      'multi-wrap-guide:create-horizontal-guide': => @createHorizontalGuide @currentCursorRow
    @subs.add atom.commands.add 'atom-workspace',
      'multi-wrap-guide:remove-guide': => @removeGuide @currentCursorRow, @currentCursorColumn

    @emitter.on 'did-toggle-lock', =>
      @locked = not @locked
      if @locked
        @lock()
      else
        @unlock()
      @redraw()
    @emitter.on 'did-toggle', =>
      @enabled = not @enabled
      @redraw()
    @emitter.on 'did-change-guides', (data) =>
      {rows: rows, columns: columns, scope: scope} = data
      # guide columns are specific to grammars, so only update for the current scope
      return unless "#{@editor.getRootScopeDescriptor()}" is "#{scope}"
      [@rows, @columns] = [rows, columns]
      @redraw()

  # Private: Sets up wrap guide configuration change event handlers.
  handleConfigEvents: ->
    updateGuidesCallback = =>
      [@rows, @columns] = [@getRows(), @getColumns()]
      @redraw()
    subs = new SubAtom
    scope = @editor.getRootScopeDescriptor()
    scopedSubscribe = (key, callback) ->
      subs.add atom.config.onDidChange key, scope: scope, callback
    scopedSubscribe 'editor.preferredLineLength', updateGuidesCallback
    scopedSubscribe 'multi-wrap-guide.columns', updateGuidesCallback
    scopedSubscribe 'multi-wrap-guide.rows', updateGuidesCallback
    subs.add atom.config.onDidChange 'multi-wrap-guide.locked', updateGuidesCallback
    subs.add atom.config.onDidChange 'multi-wrap-guide.enabled', updateGuidesCallback
    subs

  # Private: Creates a new JQuery DOM element with given type and classes.
  createElement: (type, classes...) ->
    element = $(document.createElement type)
    for c in classes
      element.addClass c
    element

  # Private: Adds given position to list of positions.
  addPosition: (pos, list) ->
    rvalue = list.slice(0)
    i = list.indexOf(pos)
    if i is -1
      rvalue.push pos
    rvalue

  # Private: Adds a new guide at the given column, if one doesn't already exist.
  createVerticalGuide: (column) ->
    return unless atom.workspace.getActiveTextEditor() is @editor
    @setColumns(@addPosition column, @columns)
    @didChangeGuides()

  # Private: Adds a new horizontal guide at the given row, if one doesn't already exist.
  createHorizontalGuide: (row) ->
    return unless atom.workspace.getActiveTextEditor() is @editor
    @setRows(@addPosition @editor.bufferRowForScreenRow(row), @rows)
    @didChangeGuides()

  # Private: Emits did-change-guides signal.
  didChangeGuides: ->
    @emitter.emit 'did-change-guides',
      rows: @rows
      columns: @columns
      scope: @editor.getRootScopeDescriptor()

  # Private: Removes a value from the list of positions, if one exists, near given position.
  removeNearPosition: (pos, list) ->
    removed = false
    rvalue = list.slice(0)
    for i in [pos, pos - 1, pos + 1, pos - 2, pos + 2]
      index = list.indexOf(i)
      if index > -1
        rvalue.splice(index, 1)
        removed = true
        break
    [removed, rvalue]

  # Private: Removes the guide at or near the given row or column, if one exists.
  removeGuide: (row, column) ->
    return unless atom.workspace.getActiveTextEditor() is @editor
    [removed, update] = @removeNearPosition column, @columns
    if removed
      @setColumns update
      @didChangeGuides()
      return
    [removed, update] = @removeNearPosition @editor.bufferRowForScreenRow(row), @rows
    if removed
      @setRows update
      @didChangeGuides()
      return

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
  mouseDownGuide: (e) =>
    return if @locked
    return if e.button
    guide = $(e.data[0])
    guide.addClass 'drag'
    guide.mouseup guide, @mouseUpGuide
    guide.mousemove guide, @mouseMoveGuide
    guide.mouseleave guide, @mouseLeaveGuide
    false

  # Private: Mouse move event handler, updates position and tip text.
  mouseMoveGuide: (e) =>
    guide = $(e.data[0])
    [offsetLeft, offsetTop] = @offsetFromMouseEvent e
    isHorizontal = guide.parent().hasClass 'horizontal'
    if isHorizontal
      targetTop = offsetTop
      guide.css 'top', "#{targetTop}px"
      offset = parseInt(guide.css 'top') + @editor.getScrollTop()
      width = @editor.getLineHeightInPixels()
    else
      targetLeft = offsetLeft
      guide.css 'left', "#{targetLeft}px"
      offset = parseInt(guide.css 'left') + @editor.getScrollLeft()
      width = @editorElement.getDefaultCharacterWidth()
    prev = (offset // width) * width
    next = (offset // width + 1) * width
    if Math.abs(offset - prev) < Math.abs(offset - next)
      position = prev // width
    else
      position = next // width
    if isHorizontal
      position = @editor.bufferRowForScreenRow(position)
    guide.prop 'title', position
    guide.find('div.multi-wrap-guide-tip').text position
    false

  # Private: Mouse up event handler, drops guide at selected column.
  mouseUpGuide: (e) =>
    guide = $(e.data[0])
    @dragEndGuide guide
    direction = if guide.parent().hasClass 'horizontal' then 'horizontal' else 'vertical'
    query = "div.#{direction} div.multi-wrap-guide-tip"
    positions = (parseInt(tip.textContent) for tip in @find query)
    if direction is 'horizontal'
      @setRows positions
    else
      @setColumns positions
    @didChangeGuides()
    @redraw()

  # Private: Returns a uniquely sorted list of numbers.
  uniqueSort: (l) ->
    $.unique(l.sort (a, b) -> a - b)

  # Private: Sets current columns and saves to config if auto save enabled.
  setColumns: (columns) ->
    @columns = @uniqueSort columns
    scopeSelector = @getRootScopeSelector()
    return unless @doAutoSave()
    atom.config.set 'multi-wrap-guide.columns', @columns, scopeSelector: scopeSelector
    n = @columns.length
    if n > 0
      atom.config.set 'editor.preferredLineLength', @columns[n - 1], scopeSelector: scopeSelector

  # Private: Sets current rows and saves to config if auto save enabled.
  setRows: (rows) ->
    @rows = @uniqueSort rows
    scopeSelector = @getRootScopeSelector()
    return unless @doAutoSave()
    atom.config.set 'multi-wrap-guide.rows', @rows, scopeSelector: scopeSelector

  # Private: Mouse leave event handler, cancels guide dragging.
  mouseLeaveGuide: (e) =>
    guide = $(e.data[0])
    @dragEndGuide guide
    @redraw()

  # Private: Ends guide dragging for the given guide.
  dragEndGuide: (guide) ->
    guide.unbind 'mouseleave'
    guide.unbind 'mousemove'
    guide.unbind 'up'
    guide.removeClass 'drag'

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

  # Private: Gets current rows configuration value.
  getRows: ->
    scope = @editor.getRootScopeDescriptor()
    defaultRows = []
    customRows = atom.config.get 'multi-wrap-guide.rows', scope: scope
    if customRows.length > 0 then customRows else defaultRows

  # Private: Creates and appends all guides to view.
  appendGuides: (positions, horizontal) ->
    lineHeight = @editor.getLineHeightInPixels()
    charWidth = @editorElement.getDefaultCharacterWidth()
    scrollTop = @editor.getScrollTop()
    scrollLeft = @editor.getScrollLeft()
    group = @createElement 'div', 'multi-wrap-guide-group'
    if horizontal
      group.addClass 'horizontal'
    else
      group.addClass 'vertical'
    for position in positions
      if group.hasClass 'horizontal'
        # don't draw very distant horizontal guides
        continue if @editor.getLineCount() + 2 * @editor.getRowsPerPage() < position
      tip = @createElement 'div', 'multi-wrap-guide-tip'
      tip.text position
      line = @createElement 'div', 'multi-wrap-guide-line'
      line.append tip
      guide = @createElement 'div', 'multi-wrap-guide'
      guide.addClass 'draggable' unless @locked
      guide.prop 'title', position
      guide.mousedown guide, @mouseDownGuide
      guide.append line
      if group.hasClass 'horizontal'
        row = @editor.screenRowForBufferRow(position)
        row += 1 if @editor.isFoldedAtBufferRow(position)
        guide.css 'top', "#{(lineHeight * row) - scrollTop}px"
      else
        guide.css 'left', "#{(charWidth * position) - scrollLeft}px"
      group.append guide
    @append group

  # Private: Redraws all current guides.
  redraw: =>
    return unless @editorElement.getDefaultCharacterWidth()
    @empty()
    return unless @enabled
    @appendGuides @columns, false
    @appendGuides @rows, true
