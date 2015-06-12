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
    rows:
      default: []
      type: 'array'
      items:
        type: 'integer'

  contextMenu: null           # Disposable object of current context menu.
  emitter: null               # Emitter object.
  enabled: true               # True iff guide lines are enabled.
  locked: false               # True iff guide lines are locked.
  subs: null                  # SubAtom object.
  views: {}                   # Hash of MultiWrapGuideView objects by editor.id.

  labelUnlockGuides: '🔓 Unlock Guides'
  labelLockGuides: '🔒 Lock Guides'
  labelDisableGuides: '❌ Disable Guides'
  labelEnableGuides: '✅ Enable Guides'
  labelCreateVerticalGuide: '⇣ Create Vertical Guide'
  labelCreateHorizontalGuide: '⇢ Create Horizontal Guide'
  labelRemoveGuide: 'Remove Guide'

  # Public: Activates package.
  activate: ->
    # performance optimization: require only after activation
    {Emitter} = require 'atom'
    SubAtom = require 'sub-atom'
    MultiWrapGuideView = require './multi-wrap-guide-view'
    @emitter = new Emitter
    @subs = new SubAtom
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

  # Public: Trigger callback on did-toggle-lock events.
  onDidToggleLock: (fn) ->
    @emitter.on 'did-toggle-lock', fn

  # Public: Trigger callback on did-toggle events.
  onDidToggle: (fn) ->
    @emitter.on 'did-toggle', fn

  # Private: Setup event handlers.
  handleEvents: ->
    @subs.add atom.commands.add 'atom-workspace',
      'multi-wrap-guide:toggle-lock': => @emitter.emit 'did-toggle-lock'
      'multi-wrap-guide:toggle': => @emitter.emit 'did-toggle'
    @onDidToggleLock =>
      @locked = not @locked
      @updateMenus()
      return unless @doAutoSave()
      atom.config.set 'multi-wrap-guide.locked', @locked
    @onDidToggle =>
      @enabled = not @enabled
      @updateMenus()
      return unless @doAutoSave()
      atom.config.set 'multi-wrap-guide.enabled', @enabled

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
      { label: @labelCreateVerticalGuide, command: 'multi-wrap-guide:create-vertical-guide' }
      { label: @labelCreateHorizontalGuide, command: 'multi-wrap-guide:create-horizontal-guide' }
      { type: 'separator' }
      { label: @labelRemoveGuide, command: 'multi-wrap-guide:remove-guide' }
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
