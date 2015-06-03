{CompositeDisposable} = require 'atom'

class MultiWrapGuideView extends HTMLDivElement
  initialize: (@editor, @editorElement) ->
    @attachToLines()
    @handleEvents()
    @updateGuides()
    this

  attachToLines: ->
    lines = @editorElement.rootElement?.querySelector?('.lines')
    lines?.appendChild(this)

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

    subscriptions.add @editor.onDidDestroy ->
      subscriptions.dispose()
      configSubscriptions.dispose()

    subscriptions.add @editorElement.onDidAttach =>
      @attachToLines()
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
    element = document.createElement(type)
    element.classList.add classes...
    element

  updateGuides: ->
    columns = @getColumns(@editor.getPath(), @editor.getGrammar().scopeName)

    if columns.length > 0 and @isEnabled()
      while @firstChild
        @removeChild @firstChild
      for column in columns
        columnWidth = @editorElement.getDefaultCharacterWidth() * column
        guide = @createElement 'div', 'multi-wrap-guide'
        guide.style.left = "#{columnWidth}px"
        guide.style.display = 'block'
        @appendChild guide
      @style.display = 'block'
    else
      @style.display = 'none'

module.exports =
document.registerElement('multi-wrap-guide',
  extends: 'div'
  prototype: MultiWrapGuideView.prototype
)
