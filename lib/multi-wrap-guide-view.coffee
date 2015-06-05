{CompositeDisposable} = require 'atom'
{View} = require 'atom-space-pen-views'
$ = require 'jquery'

module.exports =
class MultiWrapGuideView extends View
  @content: ->
    @div class:'multi-wrap-guide-view', ->

  initialize: (@editor, @editorElement) ->
    @columns = []
    @attach()
    @handleEvents()
    @updateGuides()
    @visible = true
    this

  destroy: ->
    lines = $(@editorElement.rootElement?.querySelector?('.lines'))
    lines?.find('.multi-wrap-guide')?.empty().remove()
    @subscriptions?.dispose()
    @subscriptions = null
    @configSubscriptions?.dispose()
    @configSubscriptions = null

  attach: ->
    lines = $(@editorElement.rootElement?.querySelector?('.lines'))
    lines?.append this

  toggle: ->
    @visible = not @visible
    if @visible
      @updateGuides()
    else
      @empty()

  handleEvents: ->
    updateGuidesCallback = => @updateGuides()

    @subscriptions = new CompositeDisposable
    @configSubscriptions = @handleConfigEvents()
    @subscriptions.add atom.config.onDidChange 'multi-wrap-guide.columns', updateGuidesCallback
    @subscriptions.add atom.config.onDidChange 'editor.fontSize', ->
      # setTimeout because we need to wait for the editor measurement to happen
      setTimeout(updateGuidesCallback, 0)

    @subscriptions.add atom.commands.add 'atom-text-editor',
      'multi-wrap-guide:toggle': => @toggle()

    @subscriptions.add @editor.onDidChangeScrollLeft updateGuidesCallback
    @subscriptions.add @editor.onDidChangePath updateGuidesCallback
    @subscriptions.add @editor.onDidChangeGrammar =>
      @configSubscriptions.dispose()
      @configSubscriptions = @handleConfigEvents()
      updateGuidesCallback()

    @subscriptions.add @editor.onDidDestroy =>
      @destroy()

    @subscriptions.add @editorElement.onDidAttach =>
      @attach()
      updateGuidesCallback()

  handleConfigEvents: ->
    updateGuidesCallback = => @updateGuides(true)
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

  getDefaultColumns: (scopeName) ->
    [atom.config.get 'editor.preferredLineLength', scope: [scopeName]]

  getColumns: (path, scopeName) ->
    unless @columns.length
      customColumns = atom.config.get 'multi-wrap-guide.columns'
      @columns = if customColumns.length > 0 then customColumns else @getDefaultColumns scopeName
    @columns

  isEnabled: ->
    wrap_enabled = atom.config.get 'wrap-guide.enabled',
      scope: @editor.getRootScopeDescriptor()
    if wrap_enabled? and not wrap_enabled
      return false
    return atom.config.get 'multi-wrap-guide.enabled'

  createElement: (type, classes...) ->
    element = $(document.createElement(type))
    for c in classes
      element.addClass c
    element

  mouseDown: (e) =>
    guide = $(e.data[0])
    guide.addClass 'drag'
    guide.mouseup guide, @mouseUp
    guide.mousemove guide, @mouseMove
    guide.mouseleave guide, @mouseLeave
    false

  mouseMove: (e) =>
    guide = $(e.data[0])
    scrollView = $(@editorElement.rootElement?.querySelector?('.scroll-view'))[0]
    newLeft = e.pageX - $(@editorElement).offset().left - scrollView.offsetLeft
    guide.css 'left', "#{newLeft}px"
    @setTooltip guide
    false

  mouseUp: (e) =>
    guide = $(e.data[0])
    @dragEnd guide
    @saveColumns()
    @updateGuides()

  mouseLeave: (e) =>
    @dragEnd $(e.data[0])
    @updateGuides()

  dragEnd: (guide) ->
    guide.unbind 'mouseleave'
    guide.unbind 'mousemove'
    guide.unbind 'up'
    guide.removeClass 'drag'
    false

  setTooltip: (guide) ->
    # FIXME: incorrect snapping behaviour when scroll left is > 0?
    dropOffset = parseInt(guide.css 'left')
    dropOffset += @editor.getScrollLeft() if @editorElement.hasTiledRendering
    charWidth = @editorElement.getDefaultCharacterWidth()
    leftSide = (dropOffset // charWidth) * charWidth
    leftSide += @editor.getScrollLeft() if @editorElement.hasTiledRendering
    rightSide = (dropOffset // charWidth + 1) * charWidth
    rightSide += @editor.getScrollLeft() if @editorElement.hasTiledRendering
    if Math.abs(dropOffset - leftSide) < Math.abs(dropOffset - rightSide)
      leftSide -= @editor.getScrollLeft() if @editorElement.hasTiledRendering
      column = leftSide // charWidth
    else
      rightSide -= @editor.getScrollLeft() if @editorElement.hasTiledRendering
      column = rightSide // charWidth
    tip = guide.find '.multi-wrap-guide-tip'
    tip.text column

  saveColumns: ->
    @columns = []
    for child in @children()
      tip = $(child).find('.multi-wrap-guide-tip')
      @columns.push parseInt(tip.text())
    return unless atom.config.get 'multi-wrap-guide.autoSaveChanges'
    customColumns = atom.config.get('multi-wrap-guide.columns')
    if customColumns.length > 0
      atom.config.set 'multi-wrap-guide.columns', @columns
    else
      scope = atom.workspace.getActiveTextEditor()?.getGrammar()?.scopeName
      return unless scope?
      atom.config.set 'editor.preferredLineLength', @columns[0],
        scopeSelector: ".#{scope}"

  updateGuides: (configChanged = false) =>
    if configChanged
      @columns = []
    @empty()
    return unless @isEnabled()
    columns = @getColumns(@editor.getPath(), @editor.getGrammar().scopeName)
    if columns.length > 0
      for column in columns
        columnWidth = @editorElement.getDefaultCharacterWidth() * column
        columnWidth -= @editor.getScrollLeft() if @editorElement.hasTiledRendering
        guide = @createElement 'div', 'multi-wrap-guide'
        tip = @createElement 'div', 'multi-wrap-guide-tip'
        line = @createElement 'div', 'multi-wrap-guide-line'
        line.append tip
        guide.append line
        guide.css 'left', "#{columnWidth}px"
        guide.mousedown guide, @mouseDown
        @setTooltip guide
        @append guide
      @css 'display', 'block'
    else
      @css 'display', 'none'
