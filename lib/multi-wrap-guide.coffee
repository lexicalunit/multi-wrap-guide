module.exports =
  config:
    autoSaveChanges:
      title: 'Automatically Save Changes'
      type: 'boolean'
      default: true
      description: 'Automatically save any changes to multi-wrap-guide settings to your `config.cson` file.'
    columns:
      title: 'Vertical Wrap Guide Positions'
      default: []
      type: 'array'
      items:
        type: 'integer'
      description: 'Array listing column numbers at which to draw vertical wrap guides.'
    enabled:
      title: 'Enable Package'
      type: 'boolean'
      default: true
    icons:
      title: 'Enable Icons'
      type: 'boolean'
      default: true
      description: 'Enables colorful icons in menus.'
    locked:
      title: 'Lock Guides'
      type: 'boolean'
      default: false
      description: 'Locking guides disables draggable guides.'
    rows:
      title: 'Horizontal Wrap Guide Positions'
      default: []
      type: 'array'
      items:
        type: 'integer'
      description: 'Array listing row numbers at which to draw horizontal wrap guides.'
    silent:
      title: 'Silent Guides'
      type: 'boolean'
      default: false
      description: 'Silence guide tooltips.'

  contextMenu: null           # Disposable object of current context menu.
  emitter: null               # Emitter object.
  enabled: true               # True iff guide guides are enabled.
  locked: false               # True iff guide guides are locked.
  silent: false               # True iff guide tooltips are disabled.
  subs: null                  # SubAtom object.
  views: {}                   # Hash of MultiWrapGuideView objects by editor.id.

  labelUnlockGuides: ->
    if atom.config.get 'multi-wrap-guide.icons' then '🔓 Unlock Guides' else 'Unlock Guides'
  labelLockGuides: ->
    if atom.config.get 'multi-wrap-guide.icons' then '🔒 Lock Guides' else 'Lock Guides'
  labelDisableGuides: ->
    if atom.config.get 'multi-wrap-guide.icons' then '❌ Disable Guides' else 'Disable Guides'
  labelEnableGuides: ->
    if atom.config.get 'multi-wrap-guide.icons' then '✅ Enable Guides' else 'Enable Guides'
  labelUnsilenceGuides: ->
    if atom.config.get 'multi-wrap-guide.icons' then '🔔 Unsilence Guide tooltips' else 'Unsilence Guide tooltips'
  labelSilenceGuides: ->
    if atom.config.get 'multi-wrap-guide.icons' then '🔕 Silence Guide tooltips' else 'Silence Guide tooltips'
  labelCreateVerticalGuide: ->
    if atom.config.get 'multi-wrap-guide.icons' then '⇣ Create Vertical Guide' else 'Create Vertical Guide'
  labelCreateHorizontalGuide: ->
    if atom.config.get 'multi-wrap-guide.icons' then '⇢ Create Horizontal Guide' else 'Create Horizontal Guide'
  labelLineBreak: ->
    'Line Break at Guide'
  labelRemoveGuide: ->
    'Remove Guide'

  # Public: Activates package.
  activate: ->
    # performance optimization: require only after activation
    {Emitter} = require 'atom'
    SubAtom = require 'sub-atom'
    MultiWrapGuideView = require './multi-wrap-guide-view'
    @emitter = new Emitter
    @subs = new SubAtom
    @locked = atom.config.get 'multi-wrap-guide.locked'
    @silent = atom.config.get 'multi-wrap-guide.silent'
    @enabled = atom.config.get 'multi-wrap-guide.enabled'
    @disableDefaultWrapGuidePackage()
    @handleEvents()
    atom.workspace.observeTextEditors (editor) =>
      @views[editor.id] = new MultiWrapGuideView editor, @emitter
      @subs.add editor.onDidDestroy =>
        @views[editor.id]?.destroy()
        delete @views[editor.id]
    # setTimeout avoids race condition for insertion of context menus
    setTimeout (=> @updateMenus()), 0

  # Public: Deactives Package.
  deactivate: ->
    @subs?.dispose()
    @subs = null
    @emitter?.dispose()
    @emitter = null
    @contextMenu?.dispose()
    @contextMenu = null
    for id, view of @views
      view?.destroy()
    @views = {}

  # Public: Trigger callback on did-toggle-lock events.
  onDidToggleLock: (fn) ->
    @emitter.on 'did-toggle-lock', fn

  # Public: Trigger callback on did-toggle-silent events.
  onDidToggleSilent: (fn) ->
    @emitter.on 'did-toggle-silent', fn

  # Public: Trigger callback on did-toggle events.
  onDidToggle: (fn) ->
    @emitter.on 'did-toggle', fn

  # Private: Setup event handlers.
  handleEvents: ->
    @subs.add atom.commands.add 'atom-workspace',
      'multi-wrap-guide:toggle-lock': => @emitter.emit 'did-toggle-lock'
      'multi-wrap-guide:toggle-silent': => @emitter.emit 'did-toggle-silent'
      'multi-wrap-guide:toggle': => @emitter.emit 'did-toggle'
      'multi-wrap-guide:make-current-settings-the-default': => @emitter.emit 'make-default'
      'multi-wrap-guide:save-current-settings': => @emitter.emit 'make-scope'
    @subs.add atom.config.observe 'multi-wrap-guide.icons', (_) =>
      @updateMenus()
    @onDidToggleLock =>
      @locked = not @locked
      @updateMenus()
      return unless @doAutoSave()
      atom.config.set 'multi-wrap-guide.locked', @locked
    @onDidToggleSilent =>
      @silent = not @silent
      @updateMenus()
      return unless @doAutoSave()
      atom.config.set 'multi-wrap-guide.silent', @silent
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
    @contextMenu = null
    submenu = []
    submenu.push { label: @labelCreateVerticalGuide(), command: 'multi-wrap-guide:create-vertical-guide' }
    submenu.push { label: @labelCreateHorizontalGuide(), command: 'multi-wrap-guide:create-horizontal-guide' }
    if atom.packages.getLoadedPackage('line-length-break')?
      submenu.push { label: @labelLineBreak(), command: 'multi-wrap-guide:line-break' }
    submenu.push { type: 'separator' }
    submenu.push { label: @labelRemoveGuide(), command: 'multi-wrap-guide:remove-guide' }
    submenu.push { type: 'separator' }
    if @locked
      submenu.push { label: @labelUnlockGuides(), command: 'multi-wrap-guide:toggle-lock' }
    else
      submenu.push { label: @labelLockGuides(), command: 'multi-wrap-guide:toggle-lock' }
    if @enabled
      submenu.push { label: @labelDisableGuides(), command: 'multi-wrap-guide:toggle' }
    else
      submenu.push { label: @labelEnableGuides(), command: 'multi-wrap-guide:toggle' }
    if @silent
      submenu.push { label: @labelUnsilenceGuides(), command: 'multi-wrap-guide:toggle-silent' }
    else
      submenu.push { label: @labelSilenceGuides(), command: 'multi-wrap-guide:toggle-silent' }
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
      locker.label = if @locked then @labelUnlockGuides() else @labelLockGuides()
    silencer = grab ourMenu.submenu, 'command', 'multi-wrap-guide:toggle-silent'
    if silencer?
      silencer.label = if @silent then @labelUnsilenceGuides() else @labelSilenceGuides()
    toggler = grab ourMenu.submenu, 'command', 'multi-wrap-guide:toggle'
    if toggler?
      toggler.label = if @enabled then @labelDisableGuides() else @labelEnableGuides()
    atom.menu.update()
