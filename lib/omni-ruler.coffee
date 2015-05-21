OmniRulerView = require './omni-ruler-view'

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
      omniRulerView = new OmniRulerView().initialize(editor, editorElement)
