{$} = require 'atom'

module.exports =
  configDefaults:
    rulerPositions: []

  activate: ->
    @addRuler pos for pos in atom.config.get('omni-ruler.rulerPositions')

  deactivate: ->
    @removeRuler pos for pos in atom.config.get('omni-ruler.rulerPositions')

  addRuler: (pos) ->
    atom.workspaceView.eachEditorView (ev) ->
      return if ev.hasClass('mini')

      underlayer = ev.find('.underlayer')

      ruler = $('<div class="omni-ruler wrap-guide"></div>').css
        left: (pos * ev.charWidth) + 'px'
        display: 'block'

      underlayer.append ruler

  removeRuler: (pos) ->
    atom.workspaceView.eachEditorView (ev) ->
      return if ev.hasClass('mini')
      ev.find('.underlayer').find('.omni-ruler').remove()
