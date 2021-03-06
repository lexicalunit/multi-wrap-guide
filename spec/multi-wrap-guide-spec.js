/** @babel */

describe('MultiWrapGuide', () => {
  let [MultiWrapGuide, editor, editorElement, workspaceElement] = Array.from([])

  const getLeftPosition = (element) => {
    return parseInt(element.style.left)
  }

  const getWrapGuideViews = () => {
    const wrapGuideViews = []
    atom.workspace.getTextEditors().forEach(editor => {
      wrapGuideViews.push(MultiWrapGuide.views[editor.id])
    })
    return wrapGuideViews
  }

  beforeEach(() => {
    workspaceElement = atom.views.getView(atom.workspace)
    workspaceElement.style.height = '200px'
    workspaceElement.style.width = '1500px'

    jasmine.attachToDOM(workspaceElement)

    waitsForPromise(() => atom.packages.activatePackage('language-javascript'))
    waitsForPromise(() => atom.packages.activatePackage('language-coffee-script'))
    waitsForPromise(() => atom.workspace.open('sample.js'))

    waitsForPromise(() =>
      atom.packages.activatePackage('multi-wrap-guide').then(pack => {
        MultiWrapGuide = pack.mainModule
      })
    )

    waitsFor(() => Object.keys(MultiWrapGuide.views).length > 0)
    runs(() => {
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
    })
  })

  describe('.activate', () => {
    it('appends a wrap guide to all existing and new editors', () => {
      expect(atom.workspace.getTextEditors().length).toBe(1)

      let views = getWrapGuideViews()
      expect(views.length).toBe(1)
      const group = views[0].element.querySelector('.multi-wrap-guide-group')
      expect(group).toExist()
      const guide = group.querySelector('.multi-wrap-guide')
      expect(guide).toExist()
      expect(getLeftPosition(guide)).toBeGreaterThan(0)

      atom.workspace.getActivePane().splitRight({ copyActiveItem: true })
      expect(atom.workspace.getTextEditors().length).toBe(2)
      views = getWrapGuideViews()
      expect(views.length).toBe(2)
      expect(getLeftPosition(views[0].element.querySelector('.multi-wrap-guide'))).toBeGreaterThan(0)
      expect(getLeftPosition(views[1].element.querySelector('.multi-wrap-guide'))).toBeGreaterThan(0)
    })

    it('positions the guide at the configured column', () => {
      const width = editor.getDefaultCharWidth() * MultiWrapGuide.views[editor.id].getColumns()[0]
      expect(width).toBeGreaterThan(0)
      const views = getWrapGuideViews()
      const guide = views[0].element.querySelector('.multi-wrap-guide')
      expect(getLeftPosition(guide)).toBe(parseInt(width))
      expect(guide).toBeVisible()
    })
  })

  describe('when the font size changes', () => {
    it('updates the wrap guide position', () => {
      const views = getWrapGuideViews()
      expect(views.length).toBe(1)
      let guide = views[0].element.querySelector('.multi-wrap-guide')
      const initial = getLeftPosition(guide)
      expect(initial).toBeGreaterThan(0)
      const fontSize = atom.config.get('editor.fontSize')
      atom.config.set('editor.fontSize', fontSize + 10)

      advanceClock(1)
      guide = views[0].element.querySelector('.multi-wrap-guide')
      expect(getLeftPosition(guide)).toBeGreaterThan(initial)
      expect(guide).toBeVisible()
    })
  })

  describe('when the editor\'s scroll left changes', () => {
    it('updates the wrap guide position to a relative position on screen', () => {
      editor.setText(`a long line which causes the editor to scrol!${Array(500).join('!')}`)
      editorElement.style.width = '100px'

      const views = getWrapGuideViews()
      expect(views.length).toBe(1)
      let guide = views[0].element.querySelector('.multi-wrap-guide')
      const initial = getLeftPosition(guide)
      expect(initial).toBeGreaterThan(0)

      editorElement.setScrollLeft(10)

      guide = views[0].element.querySelector('.multi-wrap-guide')
      expect(getLeftPosition(guide)).toBe(parseInt(initial - 10))
      expect(guide).toBeVisible()
    })
  })

  describe('when the editor\'s grammar changes', () => {
    it('updates the wrap guide position', () => {
      const views = getWrapGuideViews()
      expect(views.length).toBe(1)
      let guide = views[0].element.querySelector('.multi-wrap-guide')
      const initial = getLeftPosition(guide)
      expect(initial).toBeGreaterThan(0)
      expect(guide).toBeVisible()

      atom.config.set('editor.preferredLineLength', 20, { scopeSelector: '.text.plain.null-grammar' })
      atom.grammars.assignLanguageMode(editor.getBuffer(), 'text.plain.null-grammar')
      advanceClock(1)
      guide = views[0].element.querySelector('.multi-wrap-guide')
      expect(getLeftPosition(guide)).toBeLessThan(initial)
      expect(guide).toBeVisible()
    })
  })

  return describe('scoped config', () => {
    it('::getDefaultColumn returns the scope-specific column value', () => {
      atom.config.set('editor.preferredLineLength', 132, { scopeSelector: '.source.js' })
      expect(MultiWrapGuide.views[editor.id].getColumns()[0]).toBe(132)
    })
  })
})

// NOTE: Reactive-redraw when configuration values change is not currently supported.
// describe "when the column config changes", ->
//   it 'updates the guide according to scope-specific changes', ->
//     views = getWrapGuideViews()
//     expect(views.length).toBe(1)
//     wrapGuide = views[0]
//
//     spyOn(wrapGuide, 'redraw')
//
//     column = atom.config.get('editor.preferredLineLength', scope: editor.getRootScopeDescriptor())
//     atom.config.set('editor.preferredLineLength', column + 10, scope: '.source.js')
//
//     expect(wrapGuide.redraw).toHaveBeenCalled()
