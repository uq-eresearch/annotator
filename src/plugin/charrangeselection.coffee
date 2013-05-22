# Public: Plugin for storing/retrieving text selection as a character offset inside a base element
class Annotator.Plugin.CharRangeSelection extends Annotator.Plugin
  events:
    'annotationCreated': 'annotationCreated'
    'annotationsLoaded': 'annotationsLoaded'


  # Public: Setup handlers for the annotator events
  pluginInit: ->
    return unless Annotator.supported()


  # Public: Callback method for annotationCreated event. Receives an 
  # annotation and calculates the character offset, storing it in the new 
  # annotation.
  #
  # annotation - An annotation Object that was created
  #
  # Returns nothing
  annotationCreated: (annotation) ->
    # alert('annotation created - in CharRangeSelection')
    # Get the base element
    # base
    extraChars = 50

    if not annotation.ranges?
      return annotation # not anotating text

    content = cleanText(@element.text())
    range = annotation.ranges[0].normalize(@annotator.wrapper[0])

    charRange = new CharRange()
    offset = charRange.offsetsFromNormalizedRange(@annotator.wrapper[0], range)

    # Find the annotated text inside the content string
    selectedText = cleanText(annotation.quote)

    prefixStart = if offset.start - extraChars < 0 then 0 else offset.start - extraChars
    suffixEnd = if offset.end + extraChars > content.length then content.length else offset.end + extraChars
    annotation.prefix = content.slice(prefixStart, offset.start)
    annotation.suffix = content.slice(offset.end, suffixEnd)

    annotation.startOffset = offset.start
    annotation.endOffset = offset.end

    annotation


  # Find any annotations that haven't been placed, or that have been placed in correctly
  # and use the stored character offsets to place them
  annotationsLoaded: (annotations) ->
    for annotation in annotations
      if annotation.startOffset?
        if !annotation.ranges? || annotation.ranges.length == 0

          this._loadAnnotation(annotation)

        else if annotation.originalQuote != annotation.text
          # delete existing
          if annotation.highlights?
            for h in annotation.highlights
              $(h).replaceWith(h.childNodes)
          
          this._loadAnnotation(annotation)

    annotations

  # Load the annotation into the page using the character offsets
  _loadAnnotation: (annotation) ->
    head = @element[0]
    TEXT_NODE = 3

    offsets = 
      start: annotation.startOffset
      end: annotation.endOffset

    range = new CharRange().rangeFromCharOffsets(head, offsets)

    selectedText = range.toString().trim()
    if annotation.originalQuote? and annotation.originalQuote != selectedText
      console.log("PANIC: annotation is attached incorrectly. Should be: '" + annotation.originalQuote + "'. But is: '" + selectedText + "'", {range: range, annotation: annotation})
      return

#        console.log("findRange", {range: range, text: range.toString()})
    annotation.ranges = []
    annotation.ranges.push(range)

    @annotator.setupAnnotation(annotation)



# Helper functions for selecting text by character offset, with different
# html elements. Requires the contained text to be similar, excepting newlines
# and space characters.
class CharRange

  TEXT_NODE = 3

  offsetsOfString: (node, text) ->
    offsets = {}

    nodeOffset = node.textContent.indexOf(text)
    lastOffset = node.textContent.lastIndexOf(text)

    if nodeOffset != lastOffset
      console.log("PANIC - multiple positions of text found")

    offsets.start = calcCharOffset(node.textContent, nodeOffset)
    offsets.end = calcCharOffset(node.textContent, nodeOffset + text.length)

    offsets



  # Returns an object with
  offsetsFromDomRange: (node, range) ->
    range = new Annotator.Range.BrowserRange(range).normalize(node)
    this.offsetsFromNormalizedRange(node, range)
    

  offsetsFromNormalizedRange: (node, range) ->
    offsets = {}
    charCount = 0
    findOffsets = (currNode) ->
      if currNode.nodeType == TEXT_NODE
        if currNode == range.start
          offsets.start = charCount
        if currNode == range.end
          offsets.end = charCount + cleanText(currNode.textContent).length
        charCount += cleanText(currNode.textContent).length

    walkDom(node, findOffsets)

    offsets



  rangeFromCharOffsets: (node, offsets) ->
    startOffset = offsets.start
    endOffset = offsets.end
    charCount = 0 # current progress
    range = document.createRange()

    findRange = (currNode) ->
      if currNode.nodeType == TEXT_NODE
        length = cleanText(currNode.textContent).length
        if length + charCount > startOffset and charCount <= startOffset
          # start position is in here
          offset = calcNodeOffset(currNode.textContent, startOffset - charCount)
          range.setStart(currNode, offset)
        if length + charCount >= endOffset and charCount <= endOffset
          # end position is in here
          offset = calcNodeOffset(currNode.textContent, endOffset - charCount)
          range.setEnd(currNode, offset)

        charCount += length

    walkDom(node, findRange)

    range

#        console.log("findRange", {range: range, text: range.toString()})


# Returns a count used directly on the node, based on a count into a cleaned text
calcNodeOffset = (text, charOffset) ->
  nodeCount = 0
  cleanedCount = 0
  if charOffset == nodeCount
    return nodeCount
  for char in text
    nodeCount++
    if !(removeChars.test(char))
      cleanedCount++
    if charOffset == cleanedCount
      return nodeCount
  return nodeCount


# Return a char offset count, when given a node offset
calcCharOffset = (text, nodeOffset) ->
  charOffset = 0
  nodeCount = 0
  if nodeOffset == nodeCount
    return charOffset
  for char in text
    nodeCount++
    if !(removeChars.test(char))
      charOffset++
    if nodeOffset == nodeCount
      return charOffset
  return charOffset



cleanText = (text) ->
  text.replace(removeCharsGlobal, '')


removeChars = /[\n\s]/;
removeCharsGlobal = /[\n\s]/g;


walkDom = (node, func) ->
  func(node)
  node = node.firstChild
  while (node)
    walkDom(node, func)
    node = node.nextSibling





$ = Annotator.$
