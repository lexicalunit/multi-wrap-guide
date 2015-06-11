{Emitter} = require 'atom'
SubAtom = require 'sub-atom'
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

  contextMenu: null           # Disposable object of current context menu.
  emitter: null               # Emitter object.
  enabled: true               # True iff guide lines are enabled.
  locked: false               # True iff guide lines are locked.
  subs: null                  # SubAtom object.
  views: {}                   # Hash of MultiWrapGuideView objects by editor.id.

  labelUnlockGuides: '🔓Unlock Guides'
  labelLockGuides: '🔒Lock Guides'
  labelDisableGuides: '❌Disable Guides'
  labelEnableGuides: '✅Enable Guides'

  # Public: Activates package.
  activate: ->
    @subs = new SubAtom
    @emitter = new Emitter
    @locked = atom.config.get 'multi-wrap-guide.locked'
    @enabled = atom.config.get 'multi-wrap-guide.enabled'
    @disableDefaultWrapGuidePackage()
    @handleEvents()
    atom.workspace.observeTextEditors (editor) =>
      @views[editor.id] = new MultiWrapGuideView editor, @emitter
      @subs.add editor.onDidDestroy =>
        @views[editor.id].destroy()
        delete @views[editor.id]
    # setTimeout avoids race condition for insertion of context menus
    setTimeout (=> @updateMenus()), 0

  # Public: Deactives Package.
  deactivate: ->
    @subs?.dispose()
    @subs = null if @subs
    @emitter?.dispose()
    @emitter = null if @emitter
    @contextMenu?.dispose()
    @contextMenu = null if @contextMenu
    for id, view of @views
      view.destroy()
    @views = {}

  # Private: Handle did-toggle-lock event.
  onDidToggleLock: ->
    @locked = not @locked
    @updateMenus()
    return unless @doAutoSave()
    atom.config.set 'multi-wrap-guide.locked', @locked

  # Private: Handle did-toggle events.
  onDidToggle: ->
    @enabled = not @enabled
    @updateMenus()
    return unless @doAutoSave()
    atom.config.set 'multi-wrap-guide.enabled', @enabled

  # Private: Setup event handlers.
  handleEvents: ->
    @subs.add atom.commands.add 'atom-workspace',
      'multi-wrap-guide:toggle-lock': => @emitter.emit 'did-toggle-lock'
      'multi-wrap-guide:toggle': => @emitter.emit 'did-toggle'
    @emitter.on 'did-toggle-lock', => @onDidToggleLock()
    @emitter.on 'did-toggle', => @onDidToggle()

  # Private: Disables default wrap-guide package that comes with Atom.
  disableDefaultWrapGuidePackage: ->
    wrapGuide = atom.packages.getLoadedPackage('wrap-guide')
    wrapGuide?.deactivate()
    wrapGuide?.disable()

  # Private: Returns true iff we should auto save config changes.
  doAutoSave: ->
    atom.config.get 'multi-wrap-guide.autoSaveChanges'

  # Private: Updates context menu.
  updateContextMenu: ->
    @contextMenu?.dispose()
    @contextMenu = null if @contextMenu
    submenu = [
      { label: 'Create Guide', command: 'multi-wrap-guide:create-guide' }
      { label: 'Remove Guide', command: 'multi-wrap-guide:remove-guide' }
      { type: 'separator' }
    ]
    if @locked
      submenu.push { label: @labelUnlockGuides, command: 'multi-wrap-guide:toggle-lock' }
    else
      submenu.push { label: @labelLockGuides, command: 'multi-wrap-guide:toggle-lock' }
    if @enabled
      submenu.push { label: @labelDisableGuides, command: 'multi-wrap-guide:toggle' }
    else
      submenu.push { label: @labelEnableGuides, command: 'multi-wrap-guide:toggle' }
    @contextMenu = atom.contextMenu.add
      'atom-text-editor': [
        label: 'Multi Wrap Guide'
        submenu: submenu
      ]

  # Private: Updates package menu and context menus dynamically.
  updateMenus: ->
    @updateContextMenu()

    grab = (obj, attr, val) ->
      for item in obj
        if item[attr] is val
          return item

    packages = grab atom.menu.template, 'label', 'Packages'
    return unless packages?

    ourMenu = grab packages.submenu, 'label', 'Multi Wrap Guide'
    return unless ourMenu?

    locker = grab ourMenu.submenu, 'command', 'multi-wrap-guide:toggle-lock'
    if locker?
      locker.label = if @locked then @labelUnlockGuides else @labelLockGuides

    toggler = grab ourMenu.submenu, 'command', 'multi-wrap-guide:toggle'
    if toggler?
      toggler.label = if @enabled then @labelDisableGuides else @labelEnableGuides

    atom.menu.update()
