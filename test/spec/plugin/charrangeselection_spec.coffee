# charRangeSpec.coffee

describe 'Annotator.Plugin.CharRangeSelection', ->
  plugin = null
  annotation = null

  beforeEach ->
    el = $('<p>Some text</p>')[0]
    plugin = new Annotator.Plugin.CharRangeSelection(el)
    annotation =
      quote: 'text'

  describe 'events', ->


  describe 'annotationCreated', ->
    beforeEach ->
      plugin.annotationCreated(annotation)

    it 'should add offset', ->
      expect(annotation.startOffset).toBeDefined()
      expect(annotation.startOffset).toBe(4)
      expect(annotation.endOffset).toBeDefined()
      expect(annotation.endOffset).toBe(8)

    it 'should add prefix/suffix fields to the annotation', ->
      expect(annotation.prefix).toBeDefined()
      expect(annotation.prefix).toEqual('Some')
      expect(annotation.suffix).toBeDefined()
      expect(annotation.suffix).toEqual('')


  describe 'annotationsLoaded', ->
    annotations = []

    beforeEach ->
      annotation =
        startOffset: 4
        endOffset: 8
        quote: 'text'
      annotations.push(annotation)

      annotator = {}
      annotator.setupAnnotation = jasmine.createSpy('setupAnnotation')
      plugin.annotator = annotator

      plugin.annotationsLoaded(annotations)


    it 'should add ranges', ->
      expect(annotation.ranges).toBeDefined()

    it 'should call annotator.setupAnnotation', ->
      expect(plugin.annotator.setupAnnotation).toHaveBeenCalled()



describe 'CharRange', ->
  charRange = null
  node1 = null
  node2 = null
  node3 = null
  textNode1 = null

  beforeEach ->
    addFixture('charrangeselection')
    charRange = new CharRange()
    node1 = $('#text1')[0]
    textNode1 = node1.firstChild
    node2 = $('#text2')[0]
    node3 = $('#text3')[0]

  it 'can return the offsets from a range', ->
    range = document.createRange()

    expect(range).not.toBe(null);
    expect(textNode1).not.toBe(null);

    range.setStart(textNode1, 3)
    range.setEnd(textNode1, 7)

    offsets = charRange.offsetsFromNode(node1, range)
    expect(offsets.start).toEqual(3)
    expect(offsets.end).toEqual(6) # skipped ' '


  it 'can return the offsets of a string', ->
    string = 'simple'
    offsets = charRange.offsetsOfString(node1, string)

    expect(offsets.start).toEqual(4) # skipped ' '
    expect(offsets.end).toEqual(10) # skipped ' '


  it 'can round trip from a range', ->
    range = document.createRange()
    range.setStart(textNode1, 3)
    range.setEnd(textNode1, 7)

    offsets = charRange.offsetsFromNode(node1, range)

    newRange = charRange.rangeFromCharOffsets(node1, offsets)

    expect(range.toString()).toEqual(newRange.toString())



  it 'can return a range based on char offsets', ->
    offsets = 
      start: 3
      end: 7
    range = charRange.rangeFromCharOffsets(node1, offsets)

    expect(range.toString()).toEqual('e sim')


  it 'can select text from a node with different formatting', ->
    text = 'simple'

    offsets = charRange.offsetsOfString(node1, text)

    expect(offsets).toEqual({start: 4, end: 10})

    range2 = charRange.rangeFromCharOffsets(node2, offsets)
    range3 = charRange.rangeFromCharOffsets(node3, offsets)

    expect(range2.toString().trim()).toEqual(text)
    expect(range3.toString().trim()).toEqual(text)

  it 'can select text between different nodes to almost the end', ->
    text = 'e tex'

    offsets = charRange.offsetsOfString(node3, text)
    expect(offsets).toEqual({start: 15, end: 19})

    range2 = charRange.rangeFromCharOffsets(node2, offsets)

    expect(range2.toString()).toEqual(text)


  it 'can select text between different nodes to the very end', ->
    text = 'e text'

    offsets = charRange.offsetsOfString(node3, text)
    expect(offsets).toEqual({start: 15, end: 20})

    range2 = charRange.rangeFromCharOffsets(node2, offsets)

    expect(range2.toString()).toEqual(text)


  it 'can select text at the start of the node', ->
    text = 'Some s'

    offsets = charRange.offsetsOfString(node1, text)

    expect(offsets).toEqual({start: 0, end: 5})

    range2 = charRange.rangeFromCharOffsets(node2, offsets)

    expect(range2.toString()).toEqual(text)








