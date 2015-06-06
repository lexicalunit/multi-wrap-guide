{CompositeDisposable, Emitter} = require 'atom'
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
    locked:
      type: 'boolean'
      default: false

  activate: ->
    @emitter = new Emitter
    atom.packages.getLoadedPackage('wrap-guide')?.deactivate()
    atom.packages.getLoadedPackage('wrap-guide')?.disable()
    @subscriptions = new CompositeDisposable
    @views = {}
    atom.workspace.observeTextEditors (editor) =>
      @views[editor.id] = new MultiWrapGuideView editor, @emitter
      @subscriptions.add editor.onDidDestroy =>
        @views[editor.id].destroy()
        delete @views[editor.id]

  deactivate: ->
    @subscriptions?.dispose()
    @subscriptions = null if @subscriptions?
    @emitter?.dispose()
    @emitter = null if @emitter
    for id, view of @views
      view.destroy()
    @views = {}
