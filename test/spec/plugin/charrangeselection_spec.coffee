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
      plugin.annotator = annotator

      plugin.annotationsLoaded(annotations)


    it 'should add ranges', ->
      assert(annotation.ranges)

    it 'should call annotator.setupAnnotation', ->
      assert(annotator.setupAnnotation.called)

  describe 'fuzzy matching through annotationsLoaded', ->
    annotations = []
    annotator = null

    beforeEach ->
      annotation =
        startOffset: 6
        endOffset: 8
        originalQuote: 'text'
        text: 'text'

      annotator = {}
      annotator.setupAnnotation = sinon.spy()
      plugin.annotator = annotator



    it 'should add ranges', ->
      annotations.push(annotation)
      plugin.annotationsLoaded(annotations)

      assert(annotation.ranges)

    it 'should call annotator.setupAnnotation', ->
      annotations.push(annotation)
      plugin.annotationsLoaded(annotations)

      assert(annotator.setupAnnotation.called)

    it 'should also find different text', ->
      annotation.originalQuote = 'ipsum'
      annotation.text = 'ipsum'

      annotations.push(annotation)
      plugin.annotationsLoaded(annotations)

      assert(annotation.ranges)




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
    node1 = $('<p">Some simple sample text</p>')[0]
    textNode1 = node1.firstChild
    node2 = $('<p>Some<b> simp<i>le \nsampl</i>e tex</b>t</p>')[0]
    node3 = $('<pre>Some    simple sample text</pre>')[0]
    nodeTextRepeat1 = $('<p>This is some text that. This is some text.</p>')[0]
    nodeTextRepeat2 = $('<p><b>This i</b>s some text th<i>at. Thi</i>s is some text.</p>')[0]
    # selectSpan = $('#selectSpan')[0]
    selectSpan = $('<p>This is <span>some</span> text</p>')

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

    node1 = $('<p">Some simple sample text</p>')[0]

    newRange = charRange.createRangeFromOffsets(node1, offsets)

    assert.equal(range.toString(), newRange.toString())

  it 'can round trip from a range when the target node has been split', ->
    range = document.createRange()
    range.setStart(textNode1, 3)
    range.setEnd(textNode1, 7)

    offsets = charRange.offsetsFromDomRange(node1, range)

    newRange = charRange.createRangeFromOffsets(node1, offsets)

    assert.equal(range.toString(), newRange.toString())


  it 'can return a range based on char offsets', ->
    offsets = 
      start: 3
      end: 7
    range = charRange.createRangeFromOffsets(node1, offsets)

    assert.equal(range.toString(), 'e sim')


  it 'can select text from a node with different formatting', ->
    text = 'simple'

    offsets = charRange.offsetsOfString(node1, text)

    assert.deepEqual(offsets, {start: 4, end: 10})

    range2 = charRange.createRangeFromOffsets(node2, offsets)
    range3 = charRange.createRangeFromOffsets(node3, offsets)

    assert.equal(range2.toString().trim(), text)
    assert.equal(range3.toString().trim(), text)

  it 'can select text between different nodes to almost the end', ->
    text = 'e tex'

    offsets = charRange.offsetsOfString(node3, text)
    assert.deepEqual(offsets, {start: 15, end: 19})

    range2 = charRange.createRangeFromOffsets(node2, offsets)

    assert.equal(range2.toString(), text)


  it 'can select text between different nodes to the very end', ->
    text = 'e text'

    offsets = charRange.offsetsOfString(node3, text)
    assert.deepEqual(offsets, {start: 15, end: 20})

    range2 = charRange.createRangeFromOffsets(node2, offsets)

    assert.equal(range2.toString(), text)


  it 'can select text at the start of the node', ->
    text = 'Some s'

    offsets = charRange.offsetsOfString(node1, text)

    assert.deepEqual(offsets, {start: 0, end: 5})

    range2 = charRange.createRangeFromOffsets(node2, offsets)

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

    range = charRange.createRangeFromOffsets(nodeTextRepeat2, offsets)
    assert.equal(range.toString() + 2, 'This2')

  it 'can select text perfectly surrounded by a <span>', ->
    range = document.createRange()
    range.setStartBefore(selectSpan.find('span')[0])
    range.setEndAfter(selectSpan.find('span')[0])

    assert.equal(range.toString(), 'some')
    
    offsets = charRange.offsetsFromDomRange(selectSpan[0], range)
    assert.equal(offsets.start, 6)
    assert.equal(offsets.end, 10) # skipped ' '

    newRange = charRange.createRangeFromOffsets(selectSpan[0], offsets)
    assert.equal(newRange.toString() + 2, 'some2')

  # it 'can use fuzzy matching to handle changing text', ->






describe 'calcNodeOffset', ->
  it 'can returns a trivial result', ->
    result = calcNodeOffset('my text', 1)
    assert.equal(result, 1)

  it 'can skip whitespace when required', ->
    result = calcNodeOffset('my text', 3)
    assert.equal(result, 4)

  it 'ignores whitespace at the start of a node', ->
    result = calcNodeOffset(' my text', 0)
    assert.equal(result, 1)

  it 'ignores multiple white spaces at the start of a node', ->
    result = calcNodeOffset('   my text', 0)
    assert.equal(result, 3)

  it 'ignores white spaces before the selected count', ->
    result = calcNodeOffset('my. text', 4)
    assert.equal(result, 5)

  it 'ignores white spaces immediately before the selected count', ->
    result = calcNodeOffset('at. Thi', 3)
    assert.equal(result, 4)

  it 'can skip spaces and return correctly at the end of a string', ->
    result = calcNodeOffset("e si", 3)
    assert.equal(result, 4)

  it 'returns the same when no spaces and offset 0', ->
    text = 'abc'
    assert.equal(calcNodeOffset(text, 0), 0)

  it 'returns the same when no spaces and offset [end]', ->
    text = 'abc'
    assert.equal(calcNodeOffset(text, 3), 3)


  it 'returns the same when there are no spaces', ->
    text = 'abc'
    original_index = 1
    original_char = text[original_index]
    new_index = calcNodeOffset(text, original_index)
    new_char = text[new_index]

    assert.equal(new_char, original_char)
    assert.equal(new_index, original_index)


  it 'ignores white spaces immediately before the selected count', ->
    #  'a| |b|c'
    #  0   1 2 3 (ignoring spaces)
    #  0 1 2 3 4
    text = 'a bc'
    original_index = 1
    original_char = 'b'
    new_index = calcNodeOffset(text, original_index)
    new_char = text[new_index]

    assert.equal(new_char, original_char)
    assert.equal(new_index, 2)

  it 'excludes trailing spaces when finding an end offset', ->
    result = calcNodeOffset("s is some text.", 1, true)
    assert.equal(result, 1)



describe 'calcStrippedOffset', ->
  it 'returns the same for position [0]', ->
    text = 'a  bc'
    assert.equal(calcStrippedOffset(text, 0), 0)

  it 'returns the same when no spaces and offset [end]', ->
    text = 'abc'
    assert.equal(calcStrippedOffset(text, 3), 3)

  it 'skips the first character if a space', ->
    text = ' abc'
    assert.equal(calcStrippedOffset(text, 0), 0)

  it 'skips the first character if a space, to select second offset', ->
    text = ' abc'
    assert.equal(calcStrippedOffset(text, 2), 1)



describe 'fuzzy matching', ->
  it 'can find text with the wrong offset', ->
    node = $('<p>some words that dont match right</p>')

    offsets = fuzzyFindOffsetsFromText(node, 'words', 3)

    assert.equal(offsets.start, 5)
    assert.equal(offsets.end, 10)

  it 'still works with annotator_ignore content', ->
    content = '<div>
<span class="pb" annotator_ignore="true" unselectable="on" data-n="7">700</span>
<p>also, their great-etc-grandchildren, owing to miscon-
ception of certain clauses of the game laws—no crime,</p></div>'
    node = $(content)[0]
    offsets = fuzzyFindOffsetsFromText(node, 'their great', 50)
    console.log(offsets)

    assert.equal(offsets.start, 6)
    assert.equal(offsets.end, 17)

    range = new CharRange().createRangeFromOffsets(node, offsets, false)
    selectedText = range.toString()

    assert.equal(selectedText, "their great")
