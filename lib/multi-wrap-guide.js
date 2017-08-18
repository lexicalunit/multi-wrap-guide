/** @babel */

export default {
  contextMenu: null,  // Disposable object of current context menu.
  emitter: null,      // Emitter object.
  enabled: true,      // True iff guide guides are enabled.
  locked: false,      // True iff guide guides are locked.
  subs: null,         // SubAtom object.
  views: {},          // Hash of MultiWrapGuideView objects by editor.id.

  labelUnlockGuides () {
    return atom.config.get('multi-wrap-guide.icons') ? '🔓 Unlock Guides' : 'Unlock Guides'
  },
  labelLockGuides () {
    return atom.config.get('multi-wrap-guide.icons') ? '🔒 Lock Guides' : 'Lock Guides'
  },
  labelDisableGuides () {
    return atom.config.get('multi-wrap-guide.icons') ? '❌ Disable Guides' : 'Disable Guides'
  },
  labelEnableGuides () {
    return atom.config.get('multi-wrap-guide.icons') ? '✅ Enable Guides' : 'Enable Guides'
  },
  labelCreateVerticalGuide () {
    return atom.config.get('multi-wrap-guide.icons') ? '⇣ Create Vertical Guide' : 'Create Vertical Guide'
  },
  labelCreateHorizontalGuide () {
    return atom.config.get('multi-wrap-guide.icons') ? '⇢ Create Horizontal Guide' : 'Create Horizontal Guide'
  },
  labelLineBreak () {
    return 'Line Break at Guide'
  },
  labelRemoveGuide () {
    return 'Remove Guide'
  },

  // Public: Activates package.
  activate () {
    // performance optimization: require only after activation
    const {Emitter} = require('atom')
    const SubAtom = require('sub-atom')
    const MultiWrapGuideView = require('./multi-wrap-guide-view')
    this.emitter = new Emitter()
    this.subs = new SubAtom()
    this.locked = atom.config.get('multi-wrap-guide.locked')
    this.enabled = atom.config.get('multi-wrap-guide.enabled')
    this.disableDefaultWrapGuidePackage()
    this.handleEvents()
    atom.workspace.observeTextEditors(editor => {
      this.views[editor.id] = new MultiWrapGuideView({editor: editor, emitter: this.emitter})
      editor.multiwrap = this.views[editor.id]
      this.subs.add(editor.onDidDestroy(() => {
        if (this.views[editor.id] != null) {
          this.views[editor.id].destroy()
        }
        delete this.views[editor.id]
      }))
    })

    // setTimeout avoids race condition for insertion of context menus
    setTimeout(() => this.updateMenus(), 0)
  },

  // Public: Deactives Package.
  deactivate () {
    if (this.subs != null) {
      this.subs.dispose()
    }
    this.subs = null
    if (this.emitter != null) {
      this.emitter.dispose()
    }
    this.emitter = null
    if (this.contextMenu != null) {
      this.contextMenu.dispose()
    }
    this.contextMenu = null
    for (let id in this.views) {
      const view = this.views[id]
      if (view != null) {
        view.destroy()
      }
    }
    this.views = {}
  },

  // Public: Trigger callback on did-toggle-lock events.
  onDidToggleLock (fn) {
    this.emitter.on('did-toggle-lock', fn)
  },

  // Public: Trigger callback on did-toggle events.
  onDidToggle (fn) {
    this.emitter.on('did-toggle', fn)
  },

  // Private: Setup event handlers.
  handleEvents () {
    this.subs.add(atom.commands.add('atom-workspace', {
      'multi-wrap-guide:toggle-lock': () => this.emitter.emit('did-toggle-lock'),
      'multi-wrap-guide:toggle': () => this.emitter.emit('did-toggle'),
      'multi-wrap-guide:make-current-settings-the-default': () => this.emitter.emit('make-default'),
      'multi-wrap-guide:save-current-settings': () => this.emitter.emit('make-scope')
    }))
    this.subs.add(atom.config.observe('multi-wrap-guide.icons', _ => this.updateMenus()))
    this.onDidToggleLock(() => {
      this.locked = !this.locked
      this.updateMenus()
      if (!this.doAutoSave()) return
      atom.config.set('multi-wrap-guide.locked', this.locked)
    })
    this.onDidToggle(() => {
      this.enabled = !this.enabled
      this.updateMenus()
      if (!this.doAutoSave()) return
      atom.config.set('multi-wrap-guide.enabled', this.enabled)
    })
  },

  // Private: Disables default wrap-guide package that comes with Atom.
  disableDefaultWrapGuidePackage () {
    const wrapGuide = atom.packages.getLoadedPackage('wrap-guide')
    if (wrapGuide != null) {
      wrapGuide.deactivate()
      wrapGuide.disable()
    }
  },

  // Private: Returns true iff we should auto save config changes.
  doAutoSave () {
    return atom.config.get('multi-wrap-guide.autoSaveChanges')
  },

  // Private: Updates context menu.
  updateContextMenu () {
    if (this.contextMenu != null) {
      this.contextMenu.dispose()
    }
    this.contextMenu = null
    const submenu = []
    submenu.push({ label: this.labelCreateVerticalGuide(), command: 'multi-wrap-guide:create-vertical-guide' })
    submenu.push({ label: this.labelCreateHorizontalGuide(), command: 'multi-wrap-guide:create-horizontal-guide' })
    if (atom.packages.getLoadedPackage('line-length-break') != null) {
      submenu.push({ label: this.labelLineBreak(), command: 'multi-wrap-guide:line-break' })
    }
    submenu.push({ type: 'separator' })
    submenu.push({ label: this.labelRemoveGuide(), command: 'multi-wrap-guide:remove-guide' })
    submenu.push({ type: 'separator' })
    if (this.locked) {
      submenu.push({ label: this.labelUnlockGuides(), command: 'multi-wrap-guide:toggle-lock' })
    } else {
      submenu.push({ label: this.labelLockGuides(), command: 'multi-wrap-guide:toggle-lock' })
    }
    if (this.enabled) {
      submenu.push({ label: this.labelDisableGuides(), command: 'multi-wrap-guide:toggle' })
    } else {
      submenu.push({ label: this.labelEnableGuides(), command: 'multi-wrap-guide:toggle' })
    }
    this.contextMenu = atom.contextMenu.add({
      'atom-text-editor': [{
        label: 'Multi Wrap Guide',
        submenu
      }
      ]})
  },

  // Private: Updates package menu and context menus dynamically.
  updateMenus () {
    this.updateContextMenu()
    const grab = function (obj, attr, val) {
      for (let item of obj) {
        if (item[attr] === val) {
          return item
        }
      }
    }
    const packages = grab(atom.menu.template, 'label', 'Packages')
    if (packages == null) return
    const ourMenu = grab(packages.submenu, 'label', 'Multi Wrap Guide')
    if (ourMenu == null) return
    const locker = grab(ourMenu.submenu, 'command', 'multi-wrap-guide:toggle-lock')
    if (locker != null) {
      locker.label = this.locked ? this.labelUnlockGuides() : this.labelLockGuides()
    }
    const toggler = grab(ourMenu.submenu, 'command', 'multi-wrap-guide:toggle')
    if (toggler != null) {
      toggler.label = this.enabled ? this.labelDisableGuides() : this.labelEnableGuides()
    }
    atom.menu.update()
  }
}
