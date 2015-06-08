{CompositeDisposable} = require 'atom'
{View} = require 'atom-space-pen-views'
$ = require 'jquery'
SubAtom = require 'sub-atom'

module.exports =
class MultiWrapGuideView extends View
  columns: []                 # Current column widths.
  contextMenu: null           # Disposable object of current context menu.
  currentCursorColumn: null   # Current mouse position in column width.
  editor: null                # Attached editor.
  editorElement: null         # Attached editor element.
  emitter: null               # Package emitter object.
  enabled: true               # True iff guide lines are enabled.
  linesView: null             # Attached lines view.
  locked: false               # True iff guide lines are locked.
  subs: null                  # SubAtom object.
  visible: true               # True iff guide lines are currently visible.

  @content: ->
    @div class: 'multi-wrap-guide-view'

  # Public: Creates new wrap guide view for given editor.
  initialize: (@editor, @emitter, @views) ->
    @subs = new SubAtom
    scope = @editor.getRootScopeDescriptor()
    @locked = atom.config.get 'multi-wrap-guide.locked'
    @editorElement = atom.views.getView editor
    @attach()
    @handleEvents()
    @columns = @getColumns()
    @attach()
    @showGuides()
    # setTimeout avoids race condition for insertion of context menus
    setTimeout (=> @updateMenus()), 0
    this

  # Public: Destroys all wrap guides.
  destroy: ->
    @linesView.find('div.multi-wrap-guide-view').empty().remove()
    @subscriptions?.dispose()
    @subscriptions = null if @subscriptions
    @subs?.dispose()
    @subs = null if @subs
    @configSubscriptions?.dispose()
    @configSubscriptions = null if @configSubscriptions
    @contextMenu?.dispose()
    @contextMenu = null if @contextMenu

  # Private: Returns true for only the one of the existing MultiWrapGuide objects.
  isMasterView: ->
    masterId = parseInt(Object.keys(@views).sort((a, b) -> a - b)[0])
    @editor.id is masterId

  updateContextMenu: ->
    return unless @isMasterView()
    @contextMenu?.dispose()
    @contextMenu = null if @contextMenu
    submenu = [
      { label: 'Create Guide', command: 'multi-wrap-guide:create-guide' }
      { label: 'Remove Guide', command: 'multi-wrap-guide:remove-guide' }
      { type: 'separator' }
    ]
    if @locked
      submenu.push { label: '🔓Unlock Guides', command: 'multi-wrap-guide:toggle-lock' }
    else
      submenu.push { label: '🔒Lock Guides', command: 'multi-wrap-guide:toggle-lock' }
    submenu.push { type: 'separator' }
    submenu.push { label: 'Toggle Guides', command: 'multi-wrap-guide:toggle' }
    submenu.push { label: 'Disable Guides', command: 'multi-wrap-guide:disable' }
    submenu.push { label: 'Enable Guides', command: 'multi-wrap-guide:enable' }
    @contextMenu = atom.contextMenu.add
      'atom-text-editor': [
        label: 'Multi Wrap Guide'
        submenu: submenu
      ]

  # Private: Updates package menu and context menus dynamically.
  updateMenus: ->
    return unless @isMasterView()
    @updateContextMenu()

    # TODO: make these loops work as functions? For some reason it didn't work.
    packages = null
    for item in atom.menu.template
      if item.label is 'Packages'
        packages = item
        break
    return unless packages

    ourMenu = null
    for item in packages.submenu
      if item.label is 'Multi Wrap Guide'
        ourMenu = item
        break
    return unless ourMenu

    locker = null
    for item in ourMenu.submenu
      if item.command is 'multi-wrap-guide:toggle-lock'
        locker = item
        break
    return unless locker

    locker.label = if @locked then '🔓Unlock Guides' else '🔒Lock Guides'
    atom.menu.update()

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

  # Private: Toggles wrap guides on and off.
  toggle: ->
    @visible = not @visible
    if @visible
      @showGuides()
    else
      @empty()

  # Private: Disables guides for this editor.
  disable: ->
    @enabled = false
    @showGuides()
    return unless @doAutoSave()
    atom.config.set 'multi-wrap-guide.enabled', @enabled, scopeSelector: @getRootScopeSelector()

  # Private: Enables guides for this editor.
  enable: ->
    @enabled = true
    @showGuides()
    return unless @doAutoSave()
    atom.config.set 'multi-wrap-guide.enabled', @enabled, scopeSelector: @getRootScopeSelector()

  # Private: Sets up wrap guide event and command handlers.
  handleEvents: ->
    @subscriptions = new CompositeDisposable
    @configSubscriptions = @handleConfigEvents()

    showGuidesCallback = => @showGuides()
    @subscriptions.add atom.config.onDidChange 'editor.fontSize', ->
      # setTimeout() to wait for @editorElement.getDefaultCharacterWidth() measurement to happen
      setTimeout showGuidesCallback, 0
    @subscriptions.add @editor.onDidChangeScrollLeft -> showGuidesCallback()
    @subscriptions.add @editor.onDidChangePath -> showGuidesCallback()
    @subscriptions.add @editorElement.onDidAttach =>
      @attach()  # TODO: Do we *always* need to attach() here, or only sometimes?
      showGuidesCallback()
    @subscriptions.add @editor.onDidChangeGrammar =>
      @configSubscriptions.dispose()
      @configSubscriptions = @handleConfigEvents()
      @columns = @getColumns()
      showGuidesCallback()

    @subs.add @editorElement, 'mousemove', (e) =>
      @currentCursorColumn = @columnFromMouseEvent e

    # TODO: refactor toggle/enable/disable to be more like toggle-lock
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'multi-wrap-guide:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'multi-wrap-guide:disable': => @disable()
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'multi-wrap-guide:enable': => @enable()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'multi-wrap-guide:create-guide': => @createGuide @currentCursorColumn
    @subscriptions.add atom.commands.add 'atom-workspace',
      'multi-wrap-guide:remove-guide': => @removeGuide @currentCursorColumn
    @subscriptions.add atom.commands.add 'atom-workspace',
      'multi-wrap-guide:toggle-lock': => @toggleLock()

    @emitter.on 'did-change-guides', (data) =>
      return if atom.workspace.getActiveTextEditor() is @editor
      {columns, scope} = data
      return unless "#{@editor.getRootScopeDescriptor()}" is "#{scope}"
      @columns = columns
      @showGuides()
    @emitter.on 'did-toggle-lock', (locked) =>
      @locked = locked
      @showGuides()

  # Private: Sets up wrap guide configuration change event handlers.
  handleConfigEvents: ->
    updateGuidesCallback = =>
      @columns = @getColumns()
      @showGuides()
    subscriptions = new CompositeDisposable
    scope = @editor.getRootScopeDescriptor()
    subscribe = (key, callback) ->
      subscriptions.add atom.config.onDidChange key, scope: scope, callback
    subscribe 'editor.preferredLineLength', updateGuidesCallback
    subscribe 'wrap-guide.enabled', updateGuidesCallback
    subscribe 'multi-wrap-guide.enabled', updateGuidesCallback
    subscribe 'multi-wrap-guide.columns', updateGuidesCallback
    subscriptions

  # Private: Returns true iff wrap guides and this package is enabled.
  isEnabled: ->
    wrapGuideEnabled = atom.config.get 'wrap-guide.enabled',
      scope: @editor.getRootScopeDescriptor()
    return false if wrapGuideEnabled? and wrapGuideEnabled
    return @enabled

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

  # Private: Removes the guide at the given column, if one exists.
  removeGuide: (column) ->
    return unless atom.workspace.getActiveTextEditor() is @editor
    i = @columns.indexOf(column)
    if i > -1
      @columns.splice(i, 1)
    @saveColumns()
    @showGuides()
    @didChangeGuides()

  # Private: Locks guides so they can't be dragged.
  lock: ->
    for guide in @children()
      guide.classList.remove 'draggable'
    @locked = true
    @updateMenus()
    return unless @doAutoSave()
    atom.config.set 'multi-wrap-guide.locked', @locked

  # Private: Unlocks guides so they can be dragged.
  unlock: ->
    for guide in @children()
      guide.classList.add 'draggable'
    @locked = false
    @updateMenus()
    return unless @doAutoSave()
    atom.config.set 'multi-wrap-guide.locked', @locked

  # Private: Toggles guides lock for dragging.
  toggleLock: ->
    return unless @isMasterView()
    if @locked
      @unlock()
    else
      @lock()
    @emitter.emit 'did-toggle-lock', @locked

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
    if @doAutoSave()
      if @columns.length is 1
        atom.config.set 'editor.preferredLineLength', @columns[0], scopeSelector: scopeSelector
      else
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
    guide.find('div.multi-wrap-guide-tip').text column

  # Private: Returns a `scopeSelector` for `atom.config.set()`; compare to
  # `editor.getRootScopeDescriptor()` that returns a `scope` descriptor for `atom.config.get()`.
  getRootScopeSelector: ->
    ".#{@editor.getGrammar().scopeName}"

  # Private: Returns true iff autosave should occur.
  doAutoSave: ->
    scope = @editor.getRootScopeDescriptor()
    return false unless atom.config.get 'multi-wrap-guide.autoSaveChanges', scope: scope
    return false unless @isMasterView()
    true

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
    return unless @isEnabled()
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
