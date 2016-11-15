{View} = require 'atom-space-pen-views'
$ = require 'jquery'
SubAtom = require 'sub-atom'

module.exports =
class MultiWrapGuideView extends View
  columns: []                 # Current column positions.
  currentCursorColumn: null   # Current mouse position in column position.
  currentCursorRow: null      # Current mouse position in row position.
  editor: null                # Attached editor.
  editorElement: null         # Attached editor element.
  emitter: null               # Package emitter object.
  enabled: true               # True iff guide lines are enabled.
  linesView: null             # Attached lines view.
  locked: false               # True iff guide lines are locked.
  rows: []                    # Current row positions.
  silent: false               # True iff guide tooltips are disabled.
  subs: null                  # SubAtom object for general event handlers.

  @content: ->
    @div class: 'multi-wrap-guide-view'

  # Public: Creates new wrap guide view for given editor.
  initialize: (@editor, @emitter) ->
    @subs = new SubAtom
    @locked = atom.config.get 'multi-wrap-guide.locked'
    @silent = atom.config.get 'multi-wrap-guide.silent'
    @enabled = atom.config.get 'multi-wrap-guide.enabled'
    @editorElement = atom.views.getView @editor
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
    targetLeft = offsetLeft + @editorElement.getScrollLeft()
    targetTop = offsetTop + @editorElement.getScrollTop()
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
    redrawCallback = =>
      @redraw()

    # respond to editor events
    @subs.add atom.config.onDidChange 'editor.fontSize', ->
      # setTimeout() to wait for @editorElement.getDefaultCharacterWidth() measurement to happen
      setTimeout redrawCallback, 0
    @subs.add @editorElement.onDidChangeScrollLeft -> redrawCallback()
    @subs.add @editorElement.onDidChangeScrollTop -> redrawCallback()
    @subs.add @editor.onDidChangePath -> redrawCallback()
    @subs.add @editor.onDidChangeSoftWrapped -> redrawCallback()
    @subs.add @editorElement.onDidAttach =>
      @attach()
      redrawCallback()
    @subs.add @editor.onDidChangeGrammar =>
      @columns = @getColumns()
      @rows = @getRows()
      redrawCallback()

    # respond to code folding events
    gutter = @editorElement.rootElement.querySelector('.gutter')
    $(gutter).on 'click', '.line-number.foldable .icon-right', (event) ->
      redrawCallback()
    @subs.add atom.commands.add 'atom-text-editor',
      'editor:fold-all': -> redrawCallback()
      'editor:unfold-all': -> redrawCallback()
      'editor:fold-current-row': -> redrawCallback()
      'editor:unfold-current-row': -> redrawCallback()
      'editor:fold-selection': -> redrawCallback()
      'editor:fold-at-indent-level-1': -> redrawCallback()
      'editor:fold-at-indent-level-2': -> redrawCallback()
      'editor:fold-at-indent-level-3': -> redrawCallback()
      'editor:fold-at-indent-level-4': -> redrawCallback()
      'editor:fold-at-indent-level-5': -> redrawCallback()
      'editor:fold-at-indent-level-6': -> redrawCallback()
      'editor:fold-at-indent-level-7': -> redrawCallback()
      'editor:fold-at-indent-level-8': -> redrawCallback()
      'editor:fold-at-indent-level-9': -> redrawCallback()

    # respond to mouse move event to keep track of current row, col position
    @subs.add @editorElement, 'mousemove', (e) =>
      [col, row] = @positionFromMouseEvent e
      @currentCursorColumn = col
      @currentCursorRow = row

    # respond to multi-wrap-guide commands
    @subs.add atom.commands.add 'atom-workspace',
      'multi-wrap-guide:create-vertical-guide': => @createVerticalGuide @currentCursorColumn
      'multi-wrap-guide:create-horizontal-guide': => @createHorizontalGuide @currentCursorRow
      'multi-wrap-guide:remove-guide': => @removeGuide @currentCursorRow, @currentCursorColumn
      'multi-wrap-guide:line-break': => @lineBreak @currentCursorColumn

    # respond to multi-wrap-guide events
    @emitter.on 'did-toggle-lock', =>
      @silent = not @silent
      @redraw()
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
    @emitter.on 'make-default', =>
      return unless @editor is atom.workspace.getActiveTextEditor()
      @saveColumns null
      @saveRows null
    @emitter.on 'make-scope', =>
      return unless @editor is atom.workspace.getActiveTextEditor()
      scopeSelector = @getRootScopeSelector()
      @saveColumns scopeSelector
      @saveRows scopeSelector

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

  # Private: Line breaks text at guide near the given column, if one exists.
  lineBreak: (column) ->
    return unless atom.workspace.getActiveTextEditor() is @editor
    for i in [column, column - 1, column + 1, column - 2, column + 2]
      index = @columns.indexOf(i)
      if index > -1
        preferredLineLength = atom.config.settings.editor.preferredLineLength
        atom.config.settings.editor.preferredLineLength = i
        editor = atom.workspace.getActiveTextEditor()
        view = atom.views.getView editor
        atom.commands.dispatch view, 'line-length-break:break'
        atom.packages.activatePackage('line-length-break').then (pkg) ->
          atom.config.settings.editor.preferredLineLength = preferredLineLength
        break

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
      offset = parseInt(guide.css 'top') + @editorElement.getScrollTop()
      width = @editor.getLineHeightInPixels()
    else
      targetLeft = offsetLeft
      guide.css 'left', "#{targetLeft}px"
      offset = parseInt(guide.css 'left') + @editorElement.getScrollLeft()
      width = @editorElement.getDefaultCharacterWidth()
    prev = (offset // width) * width
    next = (offset // width + 1) * width
    if Math.abs(offset - prev) < Math.abs(offset - next)
      position = prev // width
    else
      position = next // width
    if isHorizontal
      position = @editor.bufferRowForScreenRow(position)
    guide.prop 'title', position unless @silent
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

  # Private: Save current columns to atom config using given scope selector.
  saveColumns: (scopeSelector) ->
    atom.config.set 'multi-wrap-guide.columns', @columns, scopeSelector: scopeSelector
    n = @columns.length
    if n > 0
      atom.config.set 'editor.preferredLineLength', @columns[n - 1], scopeSelector: scopeSelector

  # Private: Save current rows to atom config using given scope selector.
  saveRows: (scopeSelector) ->
    atom.config.set 'multi-wrap-guide.rows', @rows, scopeSelector: scopeSelector

  # Private: Sets current columns and saves to config if auto save enabled.
  setColumns: (columns) ->
    @columns = @uniqueSort columns
    @saveColumns @getRootScopeSelector() if @doAutoSave()

  # Private: Sets current rows and saves to config if auto save enabled.
  setRows: (rows) ->
    @rows = @uniqueSort rows
    @saveRows @getRootScopeSelector() if @doAutoSave()

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
    scrollTop = @editorElement.getScrollTop()
    scrollLeft = @editorElement.getScrollLeft()
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
      guide.prop 'title', position unless @silent
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
