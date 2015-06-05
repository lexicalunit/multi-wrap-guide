{CompositeDisposable} = require 'atom'
{View} = require 'atom-space-pen-views'
$ = require 'jquery'

module.exports =
class MultiWrapGuideView extends View
  columns: []
  visible: true
  editor: null
  editorElement: null
  scrollElement: null
  linesView: null

  @content: ->
    @div class:'multi-wrap-guide-view'

  # Public: Creates new wrap guide view for given editor.
  initialize: (@editor) ->
    @editorElement = atom.views.getView editor
    @scrollElement = @editorElement.rootElement?.querySelector?('div.scroll-view')
    @linesView = $(@editorElement.rootElement?.querySelector?('div.lines'))
    @attach()
    @handleEvents()
    @updateGuides()
    this

  # Public: Destroys all wrap guides.
  destroy: ->
    @linesView?.find('div.multi-wrap-guide')?.empty().remove()
    @subscriptions?.dispose()
    @subscriptions = null
    @configSubscriptions?.dispose()
    @configSubscriptions = null

  # Private: Attach wrap guides to editor.
  attach: ->
    @linesView?.append this

  # Private: Toggles wrap guides on and off.
  toggle: ->
    @visible = not @visible
    if @visible
      @showGuides()
    else
      @empty()

  # Private: Sets up wrap guide event and command handlers.
  handleEvents: ->
    showGuidesCallback = => @showGuides()
    @subscriptions = new CompositeDisposable
    @configSubscriptions = @handleConfigEvents()
    @subscriptions.add atom.config.onDidChange 'editor.fontSize', ->
      # setTimeout because we need to wait for the editor measurement to happen
      setTimeout showGuidesCallback, 0
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'multi-wrap-guide:toggle': => @toggle()
    @subscriptions.add @editor.onDidChangeScrollLeft showGuidesCallback
    @subscriptions.add @editor.onDidChangePath showGuidesCallback
    @subscriptions.add @editor.onDidChangeGrammar =>
      @configSubscriptions.dispose()
      @configSubscriptions = @handleConfigEvents()
      showGuidesCallback()
    @subscriptions.add @editor.onDidDestroy =>
      @destroy()
    @subscriptions.add @editorElement.onDidAttach =>
      @attach()
      showGuidesCallback()

  # Private: Sets up wrap guide configuration change event handlers.
  handleConfigEvents: ->
    updateGuidesCallback = => @updateGuides()
    subscriptions = new CompositeDisposable
    subscriptions.add atom.config.onDidChange(
      'editor.preferredLineLength',
      scope: @editor.getRootScopeDescriptor(),
      updateGuidesCallback)
    subscriptions.add atom.config.onDidChange(
      'wrap-guide.enabled',
      scope: @editor.getRootScopeDescriptor(),
      updateGuidesCallback)
    subscriptions.add atom.config.onDidChange(
      'multi-wrap-guide.enabled',
      updateGuidesCallback)
    subscriptions.add atom.config.onDidChange(
      'multi-wrap-guide.columns',
      updateGuidesCallback)
    subscriptions

  # Private: Gets default wrap guide column from config.
  getDefaultColumns: (scopeName) ->
    [atom.config.get 'editor.preferredLineLength', scope: [scopeName]]

  # Private: Sets column widths based on current config.
  updateColumns: (path, scopeName) ->
    customColumns = atom.config.get 'multi-wrap-guide.columns'
    @columns = if customColumns.length > 0 then customColumns else @getDefaultColumns scopeName

  # Private: Returns true iff wrap guides and this package is enabled.
  isEnabled: ->
    wrap_enabled = atom.config.get 'wrap-guide.enabled',
      scope: @editor.getRootScopeDescriptor()
    if wrap_enabled? and not wrap_enabled
      return false
    return atom.config.get 'multi-wrap-guide.enabled'

  # Private: Creates a new JQuery DOM element with given type and classes.
  createElement: (type, classes...) ->
    element = $(document.createElement type)
    for c in classes
      element.addClass c
    element

  # Private: Mouse down event handler, initiates guide dragging.
  mouseDown: (e) =>
    guide = $(e.data[0])
    guide.addClass 'drag'
    guide.mouseup guide, @mouseUp
    guide.mousemove guide, @mouseMove
    guide.mouseleave guide, @mouseLeave
    false

  # Private: Mouse move event handler, updates position and tip text.
  mouseMove: (e) =>
    guide = $(e.data[0])
    newLeft = e.pageX - $(@editorElement).offset().left - @scrollElement.offsetLeft
    guide.css 'left', "#{newLeft}px"
    @setTip guide
    false

  # Private: Mouse up event handler, drops guide at selected column.
  mouseUp: (e) =>
    guide = $(e.data[0])
    @dragEnd guide
    @saveColumns()

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
    columnWidth = @editorElement.getDefaultCharacterWidth() * column
    columnWidth -= @editor.getScrollLeft() if @editorElement.hasTiledRendering
    guide.css 'left', "#{columnWidth}px"
    @setTipColumn guide, column

  # Private: Sets the tip text based on the guide's current position.
  # Pre-condition: The tip element must be appended to the guide.
  setTip: (guide) ->
    dropOffset = parseInt(guide.css 'left')
    dropOffset += @editor.getScrollLeft() if @editorElement.hasTiledRendering
    charWidth = @editorElement.getDefaultCharacterWidth()
    leftSide = (dropOffset // charWidth) * charWidth
    rightSide = (dropOffset // charWidth + 1) * charWidth
    if Math.abs(dropOffset - leftSide) < Math.abs(dropOffset - rightSide)
      column = leftSide // charWidth
    else
      column = rightSide // charWidth
    @setTipColumn guide, column

  # Private: Sets the tip text to be the given column.
  # Pre-condition: The tip element must be appended to the guide.
  setTipColumn: (guide, column) ->
    guide.find('div.multi-wrap-guide-tip').text column

  # Private: Saves current column state, also saves to config if auto save is enabled.
  saveColumns: ->
    @columns = (parseInt(tip.textContent) for tip in @find 'div.multi-wrap-guide-tip')
    return unless atom.config.get 'multi-wrap-guide.autoSaveChanges'
    customColumns = atom.config.get 'multi-wrap-guide.columns'
    if customColumns.length > 0
      atom.config.set 'multi-wrap-guide.columns', @columns
    else
      scope = atom.workspace.getActiveTextEditor()?.getGrammar()?.scopeName
      return unless scope?
      atom.config.set 'editor.preferredLineLength', @columns[0],
        scopeSelector: ".#{scope}"

  updateGuides: ->
    @updateColumns @editor.getPath(), @editor.getGrammar().scopeName
    @showGuides()

  showGuides: =>
    @empty()
    return unless @isEnabled()
    for column in @columns
      guide = @createElement 'div', 'multi-wrap-guide'
      tip = @createElement 'div', 'multi-wrap-guide-tip'
      line = @createElement 'div', 'multi-wrap-guide-line'
      line.append tip
      guide.append line
      guide.mousedown guide, @mouseDown
      @setColumn guide, column  # must be called after appending tip
      @append guide
