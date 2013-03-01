describe "Annotator.Plugin.Image", ->
  annotator = null
  plugin = null


  beforeEach ->
    el = $("<div><div class='annotator-editor-controls'></div></div>")[0]
    annotator = new Annotator($('<div/>')[0])
    plugin = new Annotator.Plugin.Image(el)
    plugin.annotator = annotator
    plugin.pluginInit()


  describe "pluginInit", ->
    it "should register as a custom annotation type plugin", ->
      spyOn(annotator, "addAnnotationPlugin")
      plugin.pluginInit()
      expect(annotator.addAnnotationPlugin).toHaveBeenCalled()


  describe "handlesAnnotation", ->
    it "should return false for a non image annotation", ->
      annotation = {}
      expect(plugin.handlesAnnotation(annotation)).toBe(false)

    it "should return true for an image annotation", ->
      annotation = {}
      annotation.target = ''
      expect(plugin.handlesAnnotation(annotation)).toBe(true)
