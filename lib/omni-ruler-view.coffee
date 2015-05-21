{CompositeDisposable} = require 'atom'

class OmniRulerView extends HTMLDivElement
  initialize: (@editor, @editorElement) ->
    @attachToLines()
    @handleEvents()
    @updateRulers()

    this

  attachToLines: ->
    lines = @editorElement.rootElement?.querySelector?('.lines')
    lines?.appendChild(this)

  handleEvents: ->
    updateRulersCallback = => @updateRulers()

    subscriptions = new CompositeDisposable
    configSubscriptions = @handleConfigEvents()
    subscriptions.add atom.config.onDidChange('omni-ruler.columns', updateRulersCallback)
    subscriptions.add atom.config.onDidChange 'editor.fontSize', =>
      # setTimeout because we need to wait for the editor measurement to happen
      setTimeout(updateRulersCallback, 0)

    subscriptions.add @editor.onDidChangePath(updateRulersCallback)
    subscriptions.add @editor.onDidChangeGrammar =>
      configSubscriptions.dispose()
      configSubscriptions = @handleConfigEvents()
      updateRulersCallback()

    subscriptions.add @editor.onDidDestroy ->
      subscriptions.dispose()
      configSubscriptions.dispose()

    subscriptions.add @editorElement.onDidAttach =>
      @attachToLines()
      updateRulersCallback()

  handleConfigEvents: ->
    updateRulersCallback = => @updateRulers()
    subscriptions = new CompositeDisposable
    subscriptions.add atom.config.onDidChange(
      'editor.preferredLineLength',
      scope: @editor.getRootScopeDescriptor(),
      updateRulersCallback
    )
    subscriptions.add atom.config.onDidChange(
      'wrap-guide.enabled',
      scope: @editor.getRootScopeDescriptor(),
      updateRulersCallback
    )
    subscriptions

  getDefaultColumns: ->
    [atom.config.get('editor.preferredLineLength', scope: @editor.getRootScopeDescriptor())]

  getRulersColumns: (path, scopeName) ->
    customColumns = atom.config.get('omni-ruler.columns')
    return if Array.isArray(customColumns) then customColumns else @getDefaultColumns()

  isEnabled: ->
    atom.config.get('wrap-guide.enabled', scope: @editor.getRootScopeDescriptor()) ? true

  createElement: (type, classes...) ->
    element = document.createElement(type)
    element.classList.add classes...
    element

  updateRulers: ->
    columns = @getRulersColumns(@editor.getPath(), @editor.getGrammar().scopeName)

    if columns.length > 0 and @isEnabled()
      while @firstChild
        @removeChild @firstChild
      for column in columns
        columnWidth = @editorElement.getDefaultCharacterWidth() * column
        ruler = @createElement 'div', 'omni-ruler'
        ruler.style.left = "#{columnWidth}px"
        ruler.style.display = 'block'
        @appendChild ruler
      @style.display = 'block'
    else
      @style.display = 'none'

module.exports =
document.registerElement('omni-ruler',
  extends: 'div'
  prototype: OmniRulerView.prototype
)
