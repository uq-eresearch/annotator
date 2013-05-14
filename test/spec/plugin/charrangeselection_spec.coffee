# charRangeSpec.coffee

describe 'Annotator.Plugin.CharRangeSelection', ->
  plugin = null
  annotation = null
  range = null

  beforeEach ->
    el = $('<p>Some text. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate commodo lacus et hendrerit. Sed eu libero eros. Phasellus convallis scelerisque arcu pellentesque vulputate. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Sed molestie vestibulum consequat. Quisque ut luctus erat. Proin ornare scelerisque dignissim. Nulla erat ante, dictum a ornare non, scelerisque sed justo. Quisque laoreet ullamcorper elementum. Morbi vitae dignissim magna. Vivamus sit amet volutpat ipsum. Maecenas vestibulum tellus vel lectus molestie ullamcorper. Aenean porttitor justo id est molestie ullamcorper convallis nulla laoreet. Aenean pharetra ullamcorper diam et pretium. Vestibulum non varius nunc.</p>')[0]
    plugin = new Annotator.Plugin.CharRangeSelection(el)
    plugin.annotator = 
      wrapper: [el]
    range = document.createRange()
    range.setStart(el.firstChild, 5)
    range.setEnd(el.firstChild, 9)
    annotation =
      text: 'text'
      quote: 'text'
      ranges: [
        new Range.BrowserRange(range)
      ]

  describe 'events', ->


  describe 'annotationCreated', ->
    beforeEach ->
      plugin.annotationCreated(annotation)
      expect(range.toString()).toEqual('text')


    it 'should add offset', ->
      # expect(annotation.startOffset).toBeDefined()
      expect(annotation.startOffset).toBe(4)
      # expect(annotation.endOffset).toBeDefined()
      expect(annotation.endOffset).toBe(8)

    it 'should add prefix/suffix fields to the annotation', ->
      expect(annotation.prefix).toBeDefined()
      expect(annotation.prefix.length).toBeLessThan(51)
      expect(annotation.prefix).toEqual('Some')
      expect(annotation.suffix).toBeDefined()
      expect(annotation.suffix.length).toEqual(50)
      expect(annotation.suffix).toEqual('.Loremipsumdolorsitamet,consecteturadipiscingelit.')


  describe 'annotationsLoaded', ->
    annotations = []

    beforeEach ->
      annotation =
        startOffset: 4
        endOffset: 8
        quote: 'text'
        text: 'text'
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
  nodeTextRepeat1 = null
  nodeTextRepeat2 = null
  textNode1 = null
  selectSpan = null

  beforeEach ->
    addFixture('charrangeselection')
    charRange = new CharRange()
    node1 = $('#text1')[0]
    textNode1 = node1.firstChild
    node2 = $('#text2')[0]
    node3 = $('#text3')[0]
    nodeTextRepeat1 = $('#textRepeat1')[0]
    nodeTextRepeat2 = $('#textRepeat2')[0]
    selectSpan = $('#selectSpan')[0]

  afterEach ->
    clearFixtures()


  it 'can return the offsets from a range', ->
    range = document.createRange()

    expect(range).not.toBe(null);
    expect(textNode1).not.toBe(null);

    range.setStart(textNode1, 3)
    range.setEnd(textNode1, 7)

    expect(range.toString()).toEqual('e si')

    offsets = charRange.offsetsFromDomRange(node1, range)
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

    offsets = charRange.offsetsFromDomRange(node1, range)

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


  it 'can handle selections of text that are repeated later', ->
    # This is some text that. This is some text.
    range = document.createRange()

    range.setStart(nodeTextRepeat1.firstChild, 0)
    range.setEnd(nodeTextRepeat1.firstChild, 4)

    expect(range.toString()).toEqual('This')

    offsets = charRange.offsetsFromDomRange(nodeTextRepeat1, range)
    expect(offsets.start).toEqual(0)
    expect(offsets.end).toEqual(4) # skipped ' '

  it 'can select second occurance of repeated text', ->
    range = document.createRange()
    range.setStart(nodeTextRepeat1.firstChild, 24)
    range.setEnd(nodeTextRepeat1.firstChild, 28)
    expect(range.toString()).toEqual('This')

    offsets = charRange.offsetsFromDomRange(nodeTextRepeat1, range)
    expect(offsets.start).toEqual(19)
    expect(offsets.end).toEqual(23) # skipped ' '

  it 'can select second occurance of repeated text from a different complex element', ->
    range = document.createRange()
    range.setStart(nodeTextRepeat1.firstChild, 24)
    range.setEnd(nodeTextRepeat1.firstChild, 28)
    expect(range.toString() + 1).toEqual('This1')

    offsets = charRange.offsetsFromDomRange(nodeTextRepeat1, range)
    expect(offsets.start).toEqual(19)
    expect(offsets.end).toEqual(23) # skipped ' '

    range = charRange.rangeFromCharOffsets(nodeTextRepeat2, offsets)
    expect(range.toString() + 2).toEqual('This2')
    # expect(range.startOffset).toEqual(4)
    # expect(range.endOffset).toEqual(1)

  it 'can select text perfectly surrounded by a <span>', ->
    range = document.createRange()
    range.setStartBefore($('#selectSpan span')[0])
    range.setEndAfter($('#selectSpan span')[0])

    expect(range.toString()).toEqual('some')
    
    offsets = charRange.offsetsFromDomRange(selectSpan, range)
    expect(offsets.start).toEqual(6)
    expect(offsets.end).toEqual(10) # skipped ' '

    newRange = charRange.rangeFromCharOffsets(selectSpan, offsets)
    expect(newRange.toString() + 2).toEqual('some2')    





