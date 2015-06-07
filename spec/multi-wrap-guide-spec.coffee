MultiWrapGuide = require '../lib/multi-wrap-guide'

describe "MultiWrapGuide", ->
  [editor, editorElement, wrapGuideView, workspaceElement] = []

  getLeftPosition = (element) ->
    parseInt(element.style.left)

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    workspaceElement.style.height = "200px"
    workspaceElement.style.width = "1500px"

    jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      atom.packages.activatePackage('multi-wrap-guide')

    waitsForPromise ->
      atom.packages.activatePackage('language-javascript')

    waitsForPromise ->
      atom.packages.activatePackage('language-coffee-script')

    waitsForPromise ->
      atom.workspace.open('sample.js')

    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      wrapGuideView = editorElement.rootElement.querySelector(".multi-wrap-guide-view")

  describe ".activate", ->
    getWrapGuideViews  = ->
      wrapGuideViews = []
      atom.workspace.getTextEditors().forEach (editor) ->
        view = atom.views.getView(editor).rootElement.querySelector(".multi-wrap-guide-view")
        wrapGuideViews.push(view) if view
      wrapGuideViews

    it "appends a wrap guide to all existing and new editors", ->
      runs ->
        expect(atom.workspace.getPanes().length).toBe 1
        views = getWrapGuideViews()
        expect(views.length).toBe 1
        guide = views[0].firstChild
        expect(getLeftPosition(views[0].firstChild)).toBeGreaterThan(0)

        atom.workspace.getActivePane().splitRight(copyActiveItem: true)
        expect(atom.workspace.getPanes().length).toBe 2
        views = getWrapGuideViews()
        expect(views.length).toBe 2
        expect(getLeftPosition(views[0].firstChild)).toBeGreaterThan(0)
        expect(getLeftPosition(views[1].firstChild)).toBeGreaterThan(0)

    it "positions the guide at the configured column", ->
      width = editor.getDefaultCharWidth() * MultiWrapGuide.views[editor.id].getColumns()[0]
      expect(width).toBeGreaterThan(0)
      expect(getLeftPosition(wrapGuideView.firstChild)).toBe(width)
      expect(wrapGuideView.firstChild).toBeVisible()

  describe "when the font size changes", ->
    it "updates the wrap guide position", ->
      initial = getLeftPosition(wrapGuideView.firstChild)
      expect(initial).toBeGreaterThan(0)
      fontSize = atom.config.get("editor.fontSize")
      atom.config.set("editor.fontSize", fontSize + 10)

      advanceClock(1)
      expect(getLeftPosition(wrapGuideView.firstChild)).toBeGreaterThan(initial)
      expect(wrapGuideView.firstChild).toBeVisible()

  describe "when the column config changes", ->
    it "updates the wrap guide position", ->
      initial = getLeftPosition(wrapGuideView.firstChild)
      expect(initial).toBeGreaterThan(0)
      column = atom.config.get("editor.preferredLineLength")
      atom.config.set("editor.preferredLineLength", column + 10)
      expect(getLeftPosition(wrapGuideView.firstChild)).toBeGreaterThan(initial)
      expect(wrapGuideView.firstChild).toBeVisible()

      atom.config.set("editor.preferredLineLength", column - 10)
      expect(getLeftPosition(wrapGuideView.firstChild)).toBeLessThan(initial)
      expect(wrapGuideView.firstChild).toBeVisible()

  describe "when the editor's scroll left changes", ->
    it "updates the wrap guide position to a relative position on screen", ->
      editor.setText("a long line which causes the editor to scroll")
      editor.setWidth(100)

      initial = getLeftPosition(wrapGuideView.firstChild)
      expect(initial).toBeGreaterThan(0)

      editor.setScrollLeft(10)

      expect(getLeftPosition(wrapGuideView.firstChild)).toBe(initial - 10)
      expect(wrapGuideView.firstChild).toBeVisible()

  describe "when the editor's grammar changes", ->
    it "updates the wrap guide position", ->
      atom.config.set('editor.preferredLineLength', 20, scopeSelector: '.source.js')
      initial = getLeftPosition(wrapGuideView.firstChild)
      expect(initial).toBeGreaterThan(0)
      expect(wrapGuideView.firstChild).toBeVisible()

      editor.setGrammar(atom.grammars.grammarForScopeName('text.plain.null-grammar'))
      expect(getLeftPosition(wrapGuideView.firstChild)).toBeGreaterThan(initial)
      expect(wrapGuideView.firstChild).toBeVisible()

  describe 'scoped config', ->
    it '::getDefaultColumn returns the scope-specific column value', ->
      atom.config.set('editor.preferredLineLength', 132, scopeSelector: '.source.js')

      expect(MultiWrapGuide.views[editor.id].getColumns()[0]).toBe 132

    # it 'updates the guide when the scope-specific column changes', ->
    #   spyOn(wrapGuide, 'updateGuide')
    #
    #   column = atom.config.get('editor.preferredLineLength', scope: editor.getRootScopeDescriptor())
    #   atom.config.set('editor.preferredLineLength', column + 10, scope: '.source.js')
    #
    #   expect(wrapGuide.updateGuide).toHaveBeenCalled()
    #
    # it 'updates the guide when wrap-guide.enabled is set to false', ->
    #   expect(wrapGuide).toBeVisible()
    #
    #   atom.config.set('wrap-guide.enabled', false, scopeSelector: '.source.js')
    #
    #   expect(wrapGuide).not.toBeVisible()
