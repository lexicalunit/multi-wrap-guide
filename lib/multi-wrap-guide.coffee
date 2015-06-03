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
    atom.workspace.observeTextEditors (editor) ->
      editorElement = atom.views.getView(editor)
      multiWrapGuideView = new MultiWrapGuideView().initialize(editor, editorElement)
