{CompositeDisposable} = require 'atom'
{View} = require 'atom-space-pen-views'
$ = require 'jquery'

module.exports =
class MultiWrapGuideView extends View
  @content: ->
    @div class:'multi-wrap-guide-view', ->

  initialize: (@editor, @editorElement) ->
    @attach()
    @handleEvents()
    @updateGuides()
    this

  destroy: ->

  attach: ->
    lines = $(@editorElement.rootElement?.querySelector?('.lines'))
    lines?.append(this)

  handleEvents: ->
    updateGuidesCallback = => @updateGuides()

    subscriptions = new CompositeDisposable
    configSubscriptions = @handleConfigEvents()
    subscriptions.add atom.config.onDidChange('multi-wrap-guide.columns', updateGuidesCallback)
    subscriptions.add atom.config.onDidChange 'editor.fontSize', =>
      # setTimeout because we need to wait for the editor measurement to happen
      setTimeout(updateGuidesCallback, 0)

    subscriptions.add @editor.onDidChangePath(updateGuidesCallback)
    subscriptions.add @editor.onDidChangeGrammar =>
      configSubscriptions.dispose()
      configSubscriptions = @handleConfigEvents()
      updateGuidesCallback()

    # TODO: Move this into @destroy()?
    subscriptions.add @editor.onDidDestroy ->
      subscriptions.dispose()
      configSubscriptions.dispose()

    subscriptions.add @editorElement.onDidAttach =>
      @attach()
      updateGuidesCallback()

  handleConfigEvents: ->
    updateGuidesCallback = => @updateGuides()
    subscriptions = new CompositeDisposable
    subscriptions.add atom.config.onDidChange(
      'editor.preferredLineLength',
      scope: @editor.getRootScopeDescriptor(),
      updateGuidesCallback
    )
    subscriptions.add atom.config.onDidChange(
      'wrap-guide.enabled',
      scope: @editor.getRootScopeDescriptor(),
      updateGuidesCallback
    )
    subscriptions

  getDefaultColumns: (scopeName) ->
    [atom.config.get('editor.preferredLineLength', scope: [scopeName])]

  getColumns: (path, scopeName) ->
    customColumns = atom.config.get('multi-wrap-guide.columns')
    return if customColumns.length > 0 then customColumns else @getDefaultColumns(scopeName)

  isEnabled: ->
    atom.config.get('wrap-guide.enabled', scope: @editor.getRootScopeDescriptor()) ? true

  createElement: (type, classes...) ->
    element = $(document.createElement(type))
    for c in classes
      element.addClass c
    element

  mouseDown: (e) =>
    guide = $(e.data[0])
    @setTooltip guide
    guide.addClass 'drag'
    guide.mouseup guide, @mouseUp
    guide.mousemove guide, @mouseMove
    guide.mouseleave guide, @mouseLeave

  mouseMove: (e) =>
    guide = $(e.data[0])
    scrollView = $(@editorElement.rootElement?.querySelector?('.scroll-view'))[0]
    newLeft = e.pageX - $(@editorElement).offset().left - scrollView.offsetLeft
    guide.css('left', "#{newLeft}px")
    @setTooltip guide
    false

  mouseUp: (e) =>
    guide = $(e.data[0])
    @dragEnd guide
    @snapToColumn guide
    @saveColumns()

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
    tip = guide.find('.multi-wrap-guide-tip')
    dropOffset = parseInt(guide.css('left'))
    columnWidth = @editorElement.getDefaultCharacterWidth()
    leftSide = (dropOffset // columnWidth) * columnWidth
    rightSide = (dropOffset // columnWidth + 1) * columnWidth
    if Math.abs(dropOffset - leftSide) < Math.abs(dropOffset - rightSide)
      tip.text(leftSide // columnWidth)
    else
      tip.text(rightSide // columnWidth)

  snapToColumn: (guide) ->
    dropOffset = parseInt(guide.css('left'))
    columnWidth = @editorElement.getDefaultCharacterWidth()
    leftSide = (dropOffset // columnWidth) * columnWidth
    rightSide = (dropOffset // columnWidth + 1) * columnWidth
    if Math.abs(dropOffset - leftSide) < Math.abs(dropOffset - rightSide)
      guide.css 'left', "#{leftSide}px"
    else
      guide.css 'left', "#{rightSide}px"

  saveColumns: ->
    customColumns = atom.config.get('multi-wrap-guide.columns')
    if customColumns.length > 0
      columnWidth = @editorElement.getDefaultCharacterWidth()
      columns = (parseInt($(child).css('left')) / columnWidth for child in @children())
      atom.config.set('multi-wrap-guide.columns', columns)
    else
      scope = atom.workspace.getActiveTextEditor()?.getGrammar()?.scopeName
      return unless scope?
      columnWidth = @editorElement.getDefaultCharacterWidth()
      column = parseInt($(@children()[0]).css('left')) / columnWidth
      atom.config.set 'editor.preferredLineLength', column,
        scopeSelector: ".#{scope}"

  updateGuides: =>
    columns = @getColumns(@editor.getPath(), @editor.getGrammar().scopeName)
    if columns.length > 0 and @isEnabled()
      @empty()
      for column in columns
        columnWidth = @editorElement.getDefaultCharacterWidth() * column
        guide = @createElement 'div', 'multi-wrap-guide'
        tip = @createElement 'div', 'multi-wrap-guide-tip'
        line = @createElement 'div', 'multi-wrap-guide-line'
        line.append tip
        guide.append line
        guide.css('left', "#{columnWidth}px")
        guide.mousedown guide, @mouseDown
        @append guide
      @css 'display', 'block'
    else
      @css 'display', 'none'
