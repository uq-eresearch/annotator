# Public: Plugin for storing/retrieving text selection as a character offset inside a base element
class Annotator.Plugin.CharRangeSelection extends Annotator.Plugin
  events:
    'annotationCreated': 'annotationCreated'
    'annotationUpdated': 'annotationUpdated'
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

    content = @element.text()
    content = cleanText(content)

    # Find the annotated text inside the content string
    selectedText = cleanText(annotation.quote)

    offset = content.indexOf(selectedText)
    lastOffset = content.lastIndexOf(selectedText)

    if offset != lastOffset
      alert("PANIC - multiple positions of text found")

    annotation.prefix = content.slice(offset - extraChars, offset)
    annotation.suffix = content.slice(offset + selectedText.length, offset + selectedText.length + extraChars)

    annotation.startOffset = offset
    annotation.endOffset = offset + selectedText.length

    annotation



  annotationsLoaded: (annotations) ->
    # Create annotation.highlights based on character range
    head = @element[0]

    TEXT_NODE = 3

    for annotation in annotations
      if !annotation.ranges? || annotation.ranges.length == 0

        offsets = 
          start: annotation.startOffset
          end: annotation.endOffset
        charRange = new CharRange()
        range = charRange.rangeFromCharOffsets(head, offsets)

        selectedText = range.toString().trim()
        if annotation.quote != selectedText
          console.log("PANIC: annotation is attached incorrectly. Should be: '" + annotation.quote + "'. But is: '" + selectedText + "'", {range: range, annotation: annotation})

#        console.log("findRange", {range: range, text: range.toString()})
        annotation.ranges = []
        annotation.ranges.push(range)

        @annotator.setupAnnotation(annotation)
    annotations


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
  offsetsFromNode: (node, range) ->
    return this.offsetsOfString(node, range.toString())


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
