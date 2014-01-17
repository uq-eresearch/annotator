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

    range = new CharRange().createRangeFromOffsets(head, offsets)

    selectedText = range.toString().replace(/\s+/g, ' ').trim()
    if annotation.originalQuote? and annotation.originalQuote.replace(/\s+/g, ' ').trim() != selectedText

      # Attempt to match fuzzily
      offsets = fuzzyFindOffsetsFromText(head, annotation.originalQuote, offsets.start)

      range = new CharRange().createRangeFromOffsets(head, offsets, false)
      selectedText = range.toString().replace(/\s+/g, ' ').trim()
      if annotation.originalQuote? and annotation.originalQuote.replace(/\s+/g, ' ').trim() != selectedText
        console.log("PANIC: annotation is attached incorrectly. Should be: '" + annotation.originalQuote + "'. But is: '" + selectedText + "'", {range: range, annotation: annotation})
        return
      else
        console.log("FUZZY MATCHED: " + annotation.originalQuote + " to offset: " + offsets.start)


    annotation.ranges = []
    annotation.ranges.push(range)

    @annotator.setupAnnotation(annotation)

# Helper functions for selecting text by character offset, with different
# html elements. Requires the contained text to be similar, excepting newlines
# and space characters.
class CharRange
  DOM_ANNOTATOR_IGNORE_ATTRIBUTE = 'annotator_ignore'
  TEXT_NODE = 3

  offsetsOfString: (node, text) ->
    offsets = {}

    nodeOffset = node.textContent.indexOf(text)
    lastOffset = node.textContent.lastIndexOf(text)

    if nodeOffset != lastOffset
      console.log("PANIC - multiple positions of text found")

    offsets.start = calcStrippedOffset(node.textContent, nodeOffset)
    offsets.end = calcStrippedOffset(node.textContent, nodeOffset + text.length)

    offsets



  # Returns an object with
  offsetsFromDomRange: (node, range) ->
    normalizedRange = new Range.BrowserRange(range).normalize(node)
    this.offsetsFromNormalizedRange(node, normalizedRange)
    

  offsetsFromNormalizedRange: (node, normalizedRange) ->
    offsets = {}
    charCount = 0
    findOffsets = (currNode) ->
      if currNode.hasAttribute?(DOM_ANNOTATOR_IGNORE_ATTRIBUTE)
        return false
      if currNode.nodeType == TEXT_NODE
        if currNode == normalizedRange.start
          offsets.start = charCount
        if currNode == normalizedRange.end
          offsets.end = charCount + cleanText(currNode.textContent).length
        charCount += cleanText(currNode.textContent).length

    walkDom(node, findOffsets)

    offsets



  createRangeFromOffsets: (node, offsets, stripSpaces = true) ->
    startOffset = offsets.start
    endOffset = offsets.end
    charCount = 0 # current progress
    range = document.createRange()

    findRange = (currNode) ->
      if currNode.hasAttribute?(DOM_ANNOTATOR_IGNORE_ATTRIBUTE)
        return false
      if charCount >= endOffset
        return false

      if currNode.nodeType == TEXT_NODE
        if stripSpaces
          length = cleanText(currNode.textContent).length
        else
          length = currNode.textContent.length

        # start position is in this chunk
        if length + charCount > startOffset and charCount <= startOffset
          if stripSpaces
            startPos = calcNodeOffset(currNode.textContent, startOffset - charCount)
          else
            startPos = startOffset - charCount
          range.setStart(currNode, startPos)

        # end position is in this chunk
        if length + charCount >= endOffset and charCount <= endOffset
          if stripSpaces
            endPosition = calcNodeOffset(currNode.textContent, endOffset - charCount, true)
          else
            endPosition = endOffset - charCount
          range.setEnd(currNode, endPosition)

        charCount += length

    walkDom(node, findRange)

    range


# Returns a count used directly on the node, based on a count
# into a (whitespace) cleaned text
calcNodeOffset = (text, charOffset, endOffset = false) ->
  countSkippingSpaces = 0
  for char, countIncludingSpaces in text
    if countSkippingSpaces == charOffset
      if !removeChars.test(char) || endOffset
        return countIncludingSpaces

    if !removeChars.test(char)
      countSkippingSpaces++

  return countIncludingSpaces


# Return a char offset count, when given a node offset
# return an offset skipping whitespace when given a non skipped offset and some text
calcStrippedOffset = (text, unstrippedOffset) ->
  strippedOffset = 0
  unstrippedCount = 0
  if unstrippedOffset == unstrippedCount
    return strippedOffset
  for char in text
    unstrippedCount++
    if !(removeChars.test(char))
      strippedOffset++
    if unstrippedOffset == unstrippedCount
      return strippedOffset
  return strippedOffset



cleanText = (text) ->
  text.replace(removeCharsGlobal, '')


removeChars = /[\n\s]/;
removeCharsGlobal = /[\n\s]/g;

# Walk the dom tree starting with `node`
# Calling `func` on each node
# If `func` returns false, skip the current subtree
walkDom = (node, func) ->
  returnVal = func(node)
  if returnVal == false
    return
  node = node.firstChild
  while (node)
    walkDom(node, func)
    node = node.nextSibling

#
# Use the Google diff_match_patch library to search for our text
fuzzyFindOffsetsFromText = (node, pattern, loc) ->
  text = $(node).text()
  dmp = new diff_match_patch()
  location = dmp.match_main(text, pattern, loc)

  offsets =
    start: location
    end: location + pattern.length

  return offsets


$ = Annotator.$
