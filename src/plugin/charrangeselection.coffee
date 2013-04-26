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

    content = $(this.annotator.element).text()
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

    selectedText



  annotationsLoaded: (annotations) ->
    # Create annotation.highlights based on character range
    head = this.annotator.element[0]

    TEXT_NODE = 3

    for annotation in annotations
      console.log("annotationsLoaded", annotation)

      startOffset = annotation.startOffset
      endOffset = annotation.endOffset
      charCount = 0 # current progress
      range = document.createRange()

      findRange = (node) ->
        if node.nodeType == TEXT_NODE
          length = cleanText(node.textContent).length
          if length + charCount > startOffset and charCount <= startOffset
            # start position is in here
            range.setStart(node, startOffset - charCount)
          if length + charCount >= endOffset and charCount <= endOffset
            # end position is in here
            range.setEnd(node, endOffset - charCount)

          charCount += length


      walkDom(head, findRange)
      window.myrange = range
      console.log("findRange", {range: range, text: range.toString()})




cleanText = (text) ->
  text.replace(/\n/g, '')



walkDom = (node, func) ->
  func(node)
  node = node.firstChild
  while (node)
    walkDom(node, func)
    node = node.nextSibling






$ = Annotator.$
