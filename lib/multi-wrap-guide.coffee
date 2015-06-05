{CompositeDisposable} = require 'atom'
MultiWrapGuideView = require './multi-wrap-guide-view'

module.exports =
  config:
    autoSaveChanges:
      type: 'boolean'
      default: true
    columns:
      default: []
      type: 'array'
      items:
        type: 'integer'
    enabled:
      type: 'boolean'
      default: true

  activate: ->
    atom.packages.getLoadedPackage('wrap-guide')?.deactivate()
    atom.packages.getLoadedPackage('wrap-guide')?.disable()
    @subscriptions = new CompositeDisposable
    @views = {}
    atom.workspace.observeTextEditors (editor) =>
      @views[editor.id] = new MultiWrapGuideView editor
      @subscriptions.add editor.onDidDestroy =>
        @views[editor.id].destroy()
        delete @views[editor.id]

  deactivate: ->
    @subscriptions.dispose()
    @subscriptions = null
    for id, view of @views
      view.destroy()
    @views = {}
