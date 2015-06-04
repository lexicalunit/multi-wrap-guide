{CompositeDisposable} = require 'atom'
MultiWrapGuideView = require './multi-wrap-guide-view'

module.exports =
  config:
    enabled:
      type: 'boolean'
      default: true
    columns:
      default: []
      type: 'array'
      items:
        type: 'integer'

  activate: ->
    @subscriptions = new CompositeDisposable
    atom.workspace.observeTextEditors (editor) =>
      editorElement = atom.views.getView(editor)
      multiWrapGuideView = new MultiWrapGuideView editor, editorElement
      @subscriptions.add editor.onDidDestroy ->
        multiWrapGuideView.destroy()
        multiWrapGuideView = null

  deactivate: ->
    @subscriptions.dispose()
    @subscriptions = null
