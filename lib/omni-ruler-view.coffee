{$, View} = require 'atom'

module.exports =
  class OmniRulerView extends View
    @activate: ->
      atom.workspaceView.eachEditorView (editorView) ->
        if editorView.attached and editorView.getPane()
          editorView.underlayer.append(new OmniRulerView(editorView))

    @content: ->
      @div class: 'wrap-guides'

    initialize: (@editorView) ->
      @appendRulers()

      @subscribe atom.config.observe 'editor.fontSize', => @updateRulers()
      @subscribe @editorView, 'editor:min-width-changed', => @updateRulers()
      @subscribe $(window), 'resize', => @updateRulers()

    getWidthForColumn: (column) ->
      return @editorView.charWidth * column

    getDefaultColumns: ->
      return [atom.config.getPositiveInt('editor.preferredLineLength', 80)]

    getColumns: ->
      columns = atom.config.get('omni-ruler.columns')
      defaults = @getDefaultColumns()
      return if Array.isArray(columns) then columns else defaults

    appendRulers: ->
      for column in @getColumns()
        el = $('<div class="omni-ruler wrap-guide"></div>').css({
          left: @getWidthForColumn(column)
          display: 'block'
        })
        @append(el)

    updateRulers: ->
      columns = @getColumns(@editorView.getEditor().getPath())
      @find('.omni-ruler.wrap-guide').remove()
      @appendRulers()
