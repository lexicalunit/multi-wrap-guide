/** @babel */
/** @jsx etch.dom */

import etch from 'etch'
import { CompositeDisposable, Disposable } from 'atom'

export default class MultiWrapGuideView {
  constructor (props, children) {
    this.editor = props.editor
    this.emitter = props.emitter

    this.editor.multiwrap = this      // Backreference for easier debugging.
    this.currentCursorColumn = null   // Current mouse position in column position.
    this.currentCursorRow = null      // Current mouse position in row position.
    this.columns = this.getColumns()  // Current column positions.
    this.rows = this.getRows()        // Current row positions.

    etch.initialize(this)

    this.editorElement = atom.views.getView(this.editor)
    this.scrollView = this.editorElement.querySelector('.scroll-view')
    this.scrollView.append(this.element)
    this.redraw()

    this.subs = new CompositeDisposable()
    this.handleEvents()
  }

  render () {
    return (<div className='multi-wrap-guide-view'></div>)
  }

  update (props, children) {
    return etch.update(this)
  }

  destroy () {
    while (this.element.firstChild) {
      this.element.removeChild(this.element.firstChild)
    }
    this.element.remove()
    if (this.subs) this.subs.dispose()
    this.subs = null
  }

  // Returns [left, top] offsets of mouse curosr from a given mouse event.
  offsetFromMouseEvent (e) {
    const { clientX, clientY } = e
    const scrollClientRect = this.scrollView.getBoundingClientRect()
    const left = clientX - scrollClientRect.left
    const top = clientY - scrollClientRect.top
    return [left, top]
  }

  // Returns [column, row] numbers of mouse cursor from a given mouse event.
  positionFromMouseEvent (e) {
    const [offsetLeft, offsetTop] = Array.from(this.offsetFromMouseEvent(e))
    const targetLeft = offsetLeft + this.editorElement.getScrollLeft()
    const targetTop = offsetTop + this.editorElement.getScrollTop()
    let left = 0
    let column = 0
    const charWidth = this.editorElement.getDefaultCharacterWidth()
    while (targetLeft > (left + (charWidth / 2))) {
      left += charWidth
      column += 1
    }
    let top = 0
    let row = 0
    const lineHeight = this.editor.getLineHeightInPixels()
    while (targetTop > (top + (lineHeight / 2))) {
      top += lineHeight
      row += 1
    }
    return [column, row]
  }

  // Sets up wrap guide event and command handlers.
  handleEvents () {
    const redrawCallback = () => this.redraw()

    // respond to editor events
    this.subs.add(atom.config.onDidChange('editor.fontSize', () => {
      // setTimeout() to wait for editorElement.getDefaultCharacterWidth() measurement to happen
      setTimeout(redrawCallback, 0)
    }))
    this.subs.add(this.editorElement.onDidAttach(() => {
      this.scrollView = this.editorElement.querySelector('.scroll-view')
      this.scrollView.append(this.element)
      redrawCallback()
    }))
    this.subs.add(this.editorElement.onDidChangeScrollLeft(() => redrawCallback()))
    this.subs.add(this.editorElement.onDidChangeScrollTop(() => redrawCallback()))
    this.subs.add(this.editor.onDidChangePath(() => redrawCallback()))
    this.subs.add(this.editor.onDidChangeSoftWrapped(() => redrawCallback()))
    this.subs.add(this.editor.onDidChangeGrammar(() => {
      this.columns = this.getColumns()
      this.rows = this.getRows()
      redrawCallback()
    }))

    // respond to code folding events
    const gutter = this.editorElement.querySelector('.gutter')
    if (gutter) {
      gutter.onclick = event => {
        if (event.target.className === 'icon-right') {
          redrawCallback()
        }
        return true
      }
    }
    this.subs.add(atom.commands.add('atom-text-editor', {
      'editor:fold-all': () => redrawCallback(),
      'editor:unfold-all': () => redrawCallback(),
      'editor:fold-current-row': () => redrawCallback(),
      'editor:unfold-current-row': () => redrawCallback(),
      'editor:fold-selection': () => redrawCallback(),
      'editor:fold-at-indent-level-1': () => redrawCallback(),
      'editor:fold-at-indent-level-2': () => redrawCallback(),
      'editor:fold-at-indent-level-3': () => redrawCallback(),
      'editor:fold-at-indent-level-4': () => redrawCallback(),
      'editor:fold-at-indent-level-5': () => redrawCallback(),
      'editor:fold-at-indent-level-6': () => redrawCallback(),
      'editor:fold-at-indent-level-7': () => redrawCallback(),
      'editor:fold-at-indent-level-8': () => redrawCallback(),
      'editor:fold-at-indent-level-9': () => redrawCallback()
    }))

    // respond to mouse move event to keep track of current row, col position
    const mousemoveHandler = e => {
      const [col, row] = Array.from(this.positionFromMouseEvent(e))
      this.currentCursorColumn = col
      this.currentCursorRow = row
    }
    this.editorElement.addEventListener('mousemove', mousemoveHandler)
    this.subs.add(new Disposable(() =>
      this.editorElement.removeEventListener('mousemove', mousemoveHandler)
    ))

    // respond to multi-wrap-guide commands
    this.subs.add(atom.commands.add('atom-workspace', {
      'multi-wrap-guide:create-vertical-guide': {
        didDispatch: () => this.createVerticalGuide(this.currentCursorColumn),
        hiddenInCommandPalette: true
      },
      'multi-wrap-guide:create-horizontal-guide': {
        didDispatch: () => this.createHorizontalGuide(this.currentCursorRow),
        hiddenInCommandPalette: true
      },
      'multi-wrap-guide:remove-guide': {
        didDispatch: () => this.removeGuide(this.currentCursorRow, this.currentCursorColumn),
        hiddenInCommandPalette: true
      },
      'multi-wrap-guide:line-break': {
        didDispatch: () => this.lineBreak(this.currentCursorColumn),
        hiddenInCommandPalette: true
      }
    }))

    // respond to multi-wrap-guide events
    this.emitter.on('did-toggle-lock', () => {
      if (atom.config.get('multi-wrap-guide.locked')) {
        this.lock()
      } else {
        this.unlock()
      }
      this.redraw()
    })
    this.emitter.on('did-toggle', () => {
      atom.config.set('multi-wrap-guide.enabled', !atom.config.get('multi-wrap-guide.enabled'))
      this.redraw()
    })
    this.emitter.on('did-change-guides', data => {
      const { rows, columns, scope } = data
      // guide columns are specific to grammars, so only update for the current scope
      if (`${this.editor.getRootScopeDescriptor()}` !== `${scope}`) return
      [this.rows, this.columns] = Array.from([rows, columns])
      this.redraw()
    })
    this.emitter.on('make-default', () => {
      if (this.editor !== atom.workspace.getActiveTextEditor()) return
      this.saveColumns(null)
      this.saveRows(null)
    })
    this.emitter.on('make-scope', () => {
      if (this.editor !== atom.workspace.getActiveTextEditor()) return
      const scopeSelector = getRootScopeSelector(this.editor)
      this.saveColumns(scopeSelector)
      this.saveRows(scopeSelector)
    })
  }

  // Adds a new guide at the given column, if one doesn't already exist.
  createVerticalGuide (column) {
    if (atom.workspace.getActiveTextEditor() !== this.editor) return
    this.setColumns(addPosition(column, this.columns))
    this.didChangeGuides()
  }

  // Adds a new horizontal guide at the given row, if one doesn't already exist.
  createHorizontalGuide (row) {
    if (atom.workspace.getActiveTextEditor() !== this.editor) return
    this.setRows(addPosition(this.editor.bufferRowForScreenRow(row), this.rows))
    this.didChangeGuides()
  }

  // Emits did-change-guides signal.
  didChangeGuides () {
    this.emitter.emit('did-change-guides', {
      rows: this.rows,
      columns: this.columns,
      scope: this.editor.getRootScopeDescriptor()
    })
  }

  // Removes a value from the list of positions, if one exists, near given position.
  removeNearPosition (pos, list) {
    let removed = false
    const rvalue = list.slice(0)
    for (const i of [pos, pos - 1, pos + 1, pos - 2, pos + 2]) {
      const index = list.indexOf(i)
      if (index > -1) {
        rvalue.splice(index, 1)
        removed = true
        break
      }
    }
    return [removed, rvalue]
  }

  // Removes the guide at or near the given row or column, if one exists.
  removeGuide (row, column) {
    if (atom.workspace.getActiveTextEditor() !== this.editor) return
    let [removed, update] = Array.from(this.removeNearPosition(column, this.columns))
    if (removed) {
      this.setColumns(update)
      this.didChangeGuides()
      return
    }
    [removed, update] = Array.from(
      this.removeNearPosition(this.editor.bufferRowForScreenRow(row), this.rows)
    )
    if (removed) {
      this.setRows(update)
      this.didChangeGuides()
    }
  }

  // Line breaks text at guide near the given column, if one exists.
  lineBreak (column) {
    if (atom.workspace.getActiveTextEditor() !== this.editor) return
    for (const i of [column, column - 1, column + 1, column - 2, column + 2]) {
      const index = this.columns.indexOf(i)
      if (index < 0) continue
      const { preferredLineLength } = atom.config.settings.editor
      atom.config.settings.editor.preferredLineLength = i
      const editor = atom.workspace.getActiveTextEditor()
      const view = atom.views.getView(editor)
      atom.commands.dispatch(view, 'line-length-break:break')
      atom.packages.activatePackage('line-length-break').then(pkg => {
        atom.config.settings.editor.preferredLineLength = preferredLineLength
      })
      break
    }
  }

  // Locks guides so they can't be dragged.
  lock () {
    atom.config.set('multi-wrap-guide.locked', true)
    for (const guide of this.element.children) {
      guide.classList.remove('draggable')
    }
  }

  // Unlocks guides so they can be dragged.
  unlock () {
    atom.config.set('multi-wrap-guide.locked', false)
    for (const guide of this.element.children) {
      guide.classList.add('draggable')
    }
  }

  // Mouse down event handler, initiates guide dragging.
  mouseDownGuide (guide, event) {
    if (atom.config.get('multi-wrap-guide.locked')) return
    if (event.button) return
    guide.classList.add('drag')
    guide.onmouseup = event => this.mouseUpGuide(guide, event)
    guide.onmousemove = event => this.mouseMoveGuide(guide, event)
    guide.onmouseleave = event => this.mouseLeaveGuide(guide, event)
    return false
  }

  // Mouse move event handler, updates position and tip text.
  mouseMoveGuide (guide, event) {
    let offset, position, width
    const [offsetLeft, offsetTop] = Array.from(this.offsetFromMouseEvent(event))
    const isHorizontal = guide.parentElement.classList.contains('horizontal')
    if (isHorizontal) {
      const targetTop = offsetTop
      guide.style.top = `${targetTop}px`
      offset = parseInt(guide.style.top) + this.editorElement.getScrollTop()
      width = this.editor.getLineHeightInPixels()
    } else {
      const targetLeft = offsetLeft
      guide.style.left = `${targetLeft}px`
      offset = parseInt(guide.style.left) + this.editorElement.getScrollLeft()
      width = this.editorElement.getDefaultCharacterWidth()
    }
    const prev = (Math.floor(offset / width)) * width
    const next = (Math.floor(offset / width) + 1) * width
    if (Math.abs(offset - prev) < Math.abs(offset - next)) {
      position = Math.floor(prev / width)
    } else {
      position = Math.floor(next / width)
    }
    if (isHorizontal) {
      position = this.editor.bufferRowForScreenRow(position)
    }
    guide.querySelector('div.multi-wrap-guide-tip').textContent = position
    return false
  }

  // Mouse up event handler, drops guide at selected column.
  mouseUpGuide (guide, event) {
    this.dragEndGuide(guide)
    const parentClassList = guide.parentElement.classList
    const direction = parentClassList.contains('horizontal') ? 'horizontal' : 'vertical'
    const query = `div.${direction} div.multi-wrap-guide-tip`
    const positions = []
    for (const tip of this.element.querySelectorAll(query)) {
      positions.push(parseInt(tip.textContent))
    }
    if (direction === 'horizontal') {
      this.setRows(positions)
    } else {
      this.setColumns(positions)
    }
    this.didChangeGuides()
    this.redraw()
  }

  // Mouse leave event handler, cancels guide dragging.
  mouseLeaveGuide (guide, event) {
    this.dragEndGuide(guide)
    this.redraw()
  }

  // Ends guide dragging for the given guide.
  dragEndGuide (guide) {
    delete guide.onmouseleave
    delete guide.onmousemove
    delete guide.onmouseup
    guide.classList.remove('drag')
  }

  // Save current columns to atom config using given scope selector.
  saveColumns (scopeSelector) {
    atom.config.set('multi-wrap-guide.columns', this.columns, { scopeSelector })
    const n = this.columns.length
    if (n > 0) {
      atom.config.set('editor.preferredLineLength', this.columns[n - 1], { scopeSelector })
    }
  }

  // Save current rows to atom config using given scope selector.
  saveRows (scopeSelector) {
    atom.config.set('multi-wrap-guide.rows', this.rows, { scopeSelector })
  }

  // Sets current columns and saves to config if auto save enabled.
  setColumns (columns) {
    this.columns = uniqueSort(columns)
    if (shouldAutoSave()) { this.saveColumns(getRootScopeSelector(this.editor)) }
  }

  // Sets current rows and saves to config if auto save enabled.
  setRows (rows) {
    this.rows = uniqueSort(rows)
    if (shouldAutoSave()) { this.saveRows(getRootScopeSelector(this.editor)) }
  }

  // Creates and appends all guides to view.
  appendGuides (positions, horizontal) {
    const lineHeight = this.editor.getLineHeightInPixels()
    const charWidth = this.editorElement.getDefaultCharacterWidth()
    const scrollTop = this.editorElement.getScrollTop()
    const scrollLeft = this.editorElement.getScrollLeft()
    const group = createElement('div', 'multi-wrap-guide-group')
    if (horizontal) {
      group.classList.add('horizontal')
    } else {
      group.classList.add('vertical')
    }
    for (const position of positions) {
      if (group.classList.contains('horizontal')) {
        // don't draw very distant horizontal guides
        if ((this.editor.getLineCount() + (2 * this.editor.getRowsPerPage())) < position) continue
      }
      const tip = createElement('div', 'multi-wrap-guide-tip')
      tip.textContent = position
      const line = createElement('div', 'multi-wrap-guide-line')
      line.append(tip)
      const guide = createElement('div', 'multi-wrap-guide')
      if (!atom.config.get('multi-wrap-guide.locked')) { guide.classList.add('draggable') }
      guide.onmousedown = event => this.mouseDownGuide(guide, event)
      guide.append(line)
      if (group.classList.contains('horizontal')) {
        let row = this.editor.screenRowForBufferRow(position)
        if (this.editor.isFoldedAtBufferRow(position)) { row += 1 }
        guide.style.top = `${(lineHeight * row) - scrollTop}px`
      } else {
        guide.style.left = `${(charWidth * position) - scrollLeft}px`
      }
      group.append(guide)
    }
    this.element.append(group)
  }

  // Redraws all current guides.
  redraw () {
    if (!this.editorElement.getDefaultCharacterWidth()) return
    while (this.element.firstChild) {
      this.element.removeChild(this.element.firstChild)
    }
    if (!atom.config.get('multi-wrap-guide.enabled')) return
    this.appendGuides(this.columns, false)
    this.appendGuides(this.rows, true)
  }

  // Gets current columns configuration value.
  getColumns () {
    const scope = this.editor.getRootScopeDescriptor()
    const defaultColumns = [atom.config.get('editor.preferredLineLength', { scope })]
    const customColumns = atom.config.get('multi-wrap-guide.columns', { scope })
    return customColumns.length > 0 ? customColumns : defaultColumns
  }

  // Gets current rows configuration value.
  getRows () {
    const scope = this.editor.getRootScopeDescriptor()
    const defaultRows = []
    const customRows = atom.config.get('multi-wrap-guide.rows', { scope })
    return customRows.length > 0 ? customRows : defaultRows
  }
}

// Creates a new HTMLElement with given type and classes.
function createElement (type, ...classes) {
  const element = document.createElement(type)
  for (const c of classes) {
    element.classList.add(c)
  }
  return element
}

// Adds given position to list of positions.
function addPosition (pos, list) {
  const rvalue = list.slice(0)
  const i = list.indexOf(pos)
  if (i === -1) {
    rvalue.push(pos)
  }
  return rvalue
}

// Returns a sorted list of unique numbers.
function uniqueSort (l) {
  return [...new Set(l)].sort((a, b) => a - b)
}

// Returns true iff autosave should occur.
function shouldAutoSave () {
  return atom.config.get('multi-wrap-guide.autoSaveChanges')
}

// Returns a `scopeSelector` for `atom.config.set()` compare to `editor.getRootScopeDescriptor()`
// that returns a `scope` descriptor for `atom.config.get()`.
function getRootScopeSelector (editor) {
  return `.${editor.getGrammar().scopeName}`
}
