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
      assert.equal(range.toString(), 'text')


    it 'should add offset', ->
      # expect(annotation.startOffset).toBeDefined()
      assert.equal(annotation.startOffset, 4)
      # expect(annotation.endOffset).toBeDefined()
      assert.equal(annotation.endOffset, 8)

    it 'should add prefix/suffix fields to the annotation', ->
      assert(annotation.prefix)
      assert.operator(annotation.prefix.length, '<', 51)
      assert.equal(annotation.prefix, 'Some')
      assert(annotation.suffix)
      assert.equal(annotation.suffix.length, 50)
      assert.equal(annotation.suffix, '.Loremipsumdolorsitamet,consecteturadipiscingelit.')


  describe 'annotationsLoaded', ->
    annotations = []
    annotator = null

    beforeEach ->
      annotation =
        startOffset: 4
        endOffset: 8
        quote: 'text'
        text: 'text'
      annotations.push(annotation)

      annotator = {}
      annotator.setupAnnotation = sinon.spy()
      # sinon.stub(annotator, 'setupAnnotation').returns(null)
      # annotator.setupAnnotation = jasmine.createSpy('setupAnnotation')
      plugin.annotator = annotator

      plugin.annotationsLoaded(annotations)


    it 'should add ranges', ->
      assert(annotation.ranges)

    it 'should call annotator.setupAnnotation', ->
      assert(annotator.setupAnnotation.called)
      # expect(plugin.annotator.setupAnnotation).toHaveBeenCalled()



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
    addFixture 'charrangeselection'
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

    assert.isNotNull(range);
    assert.isNotNull(textNode1);

    range.setStart(textNode1, 3)
    range.setEnd(textNode1, 7)

    assert.equal(range.toString(), 'e si')

    offsets = charRange.offsetsFromDomRange(node1, range)
    assert.equal(offsets.start, 3)
    assert.equal(offsets.end, 6) # skipped ' '


  it 'can return the offsets of a string', ->
    string = 'simple'
    offsets = charRange.offsetsOfString(node1, string)

    assert.equal(offsets.start, 4) # skipped ' '
    assert.equal(offsets.end, 10) # skipped ' '


  it 'can round trip from a range', ->
    range = document.createRange()
    range.setStart(textNode1, 3)
    range.setEnd(textNode1, 7)

    offsets = charRange.offsetsFromDomRange(node1, range)

    newRange = charRange.rangeFromCharOffsets(node1, offsets)

    assert.equal(range.toString(), newRange.toString())


  it 'can return a range based on char offsets', ->
    offsets = 
      start: 3
      end: 7
    range = charRange.rangeFromCharOffsets(node1, offsets)

    assert.equal(range.toString(), 'e sim')


  it 'can select text from a node with different formatting', ->
    text = 'simple'

    offsets = charRange.offsetsOfString(node1, text)

    assert.deepEqual(offsets, {start: 4, end: 10})

    range2 = charRange.rangeFromCharOffsets(node2, offsets)
    range3 = charRange.rangeFromCharOffsets(node3, offsets)

    assert.equal(range2.toString().trim(), text)
    assert.equal(range3.toString().trim(), text)

  it 'can select text between different nodes to almost the end', ->
    text = 'e tex'

    offsets = charRange.offsetsOfString(node3, text)
    assert.deepEqual(offsets, {start: 15, end: 19})

    range2 = charRange.rangeFromCharOffsets(node2, offsets)

    assert.equal(range2.toString(), text)


  it 'can select text between different nodes to the very end', ->
    text = 'e text'

    offsets = charRange.offsetsOfString(node3, text)
    assert.deepEqual(offsets, {start: 15, end: 20})

    range2 = charRange.rangeFromCharOffsets(node2, offsets)

    assert.equal(range2.toString(), text)


  it 'can select text at the start of the node', ->
    text = 'Some s'

    offsets = charRange.offsetsOfString(node1, text)

    assert.deepEqual(offsets, {start: 0, end: 5})

    range2 = charRange.rangeFromCharOffsets(node2, offsets)

    assert.equal(range2.toString(), text)


  it 'can handle selections of text that are repeated later', ->
    # This is some text that. This is some text.
    range = document.createRange()

    range.setStart(nodeTextRepeat1.firstChild, 0)
    range.setEnd(nodeTextRepeat1.firstChild, 4)

    assert.equal(range.toString(), 'This')

    offsets = charRange.offsetsFromDomRange(nodeTextRepeat1, range)
    assert.equal(offsets.start, 0)
    assert.equal(offsets.end, 4) # skipped ' '

  it 'can select second occurance of repeated text', ->
    range = document.createRange()
    range.setStart(nodeTextRepeat1.firstChild, 24)
    range.setEnd(nodeTextRepeat1.firstChild, 28)
    assert.equal(range.toString(), 'This')

    offsets = charRange.offsetsFromDomRange(nodeTextRepeat1, range)
    assert.equal(offsets.start, 19)
    assert.equal(offsets.end, 23) # skipped ' '

  it 'can select second occurance of repeated text from a different complex element', ->
    range = document.createRange()
    range.setStart(nodeTextRepeat1.firstChild, 24)
    range.setEnd(nodeTextRepeat1.firstChild, 28)
    assert.equal(range.toString() + 1, 'This1')

    offsets = charRange.offsetsFromDomRange(nodeTextRepeat1, range)
    assert.equal(offsets.start, 19)
    assert.equal(offsets.end, 23) # skipped ' '

    range = charRange.rangeFromCharOffsets(nodeTextRepeat2, offsets)
    assert.equal(range.toString() + 2, 'This2')
    # assert.equal(range.startOffset, 4)
    # assert.equal(range.endOffset, 1)

  it 'can select text perfectly surrounded by a <span>', ->
    range = document.createRange()
    range.setStartBefore($('#selectSpan span')[0])
    range.setEndAfter($('#selectSpan span')[0])

    assert.equal(range.toString(), 'some')
    
    offsets = charRange.offsetsFromDomRange(selectSpan, range)
    assert.equal(offsets.start, 6)
    assert.equal(offsets.end, 10) # skipped ' '

    newRange = charRange.rangeFromCharOffsets(selectSpan, offsets)
    assert.equal(newRange.toString() + 2, 'some2')    





