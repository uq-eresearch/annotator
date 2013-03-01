# Possible Libraries
# https://github.com/flipbit/jquery-image-annotate
# http://odyniec.net/projects/imgareaselect/
# http://deepliquid.com/content/Jcrop.html


# Public: Image region plugin allows users to select a region in
# an image as the target of the annotation.
class Annotator.Plugin.Image extends Annotator.Plugin

  currentImage: null
  selection: null

  # Public: Initialises the plugin
  pluginInit: ->
    # Add image area select to all the appropriate images
    @element.find('img').imgAreaSelect({
        handles: true,
        onSelectEnd: this._onSelectEnd
        onSelectStart: this._onSelectStart
        })
    jQuery(document).bind({
      "mousedown": this.deselect
    })

    # Add this plugin as a handler for annotations with an
    # 'image' target
    @annotator.addAnnotationPlugin this

    # with a callback to creating an image annotation


    # Setup listeners to show existing annotations
    this._setupListeners()

  deselect: =>
    if @currentImage
      jQuery(@currentImage).imgAreaSelect(instance: true).cancelSelection()

  # Handler for when an image region is selected
  # Show the adder in an appropriate position
  _onSelectEnd: (img, selection) =>
    if selection.width == 0 or selection.height == 0
      @annotator.adder.hide()
      return

    # save locally
    @currentImage = img
    @selection = selection

    imgPosition = jQuery(img).position()
    adderPosition = {
      top: imgPosition.top + selection.y1 - 5,
      left: imgPosition.left + selection.x2 + 5
    }

    @annotator.adder.data('selection', selection)
    @annotator.adder.css(adderPosition).show()

  _onSelectStart: (img, selection) =>
    @adder?.removeData('selection')
    @annotator.adder.hide()

  # Listens to annotation change events on the annotator in order
  # to refresh the displayed image annotations
  _setupListeners: ->
    events = [
      'annotationsLoaded', 'annotationCreated',
      'annotationUpdated', 'annotationDeleted'
    ]

    for event in events
      @annotator.subscribe event, this.updateImageHighlights
    this

  # Public: Checks whether this plugin has special code for handling
  # particular types of annotations. eg. specific target resources/selectors
  handlesAnnotation: (annotation) ->
    if annotation.target?
      return true
    else
      return false

  setupAnnotation: (annotation) ->


    annotation


  # Public: Updates the displayed highlighted regions of images
  updateImageHighlights: =>
    this


class Annotator.Annotation
  displayMarker: ->



class Annotator.ImageAnnotation extends Annotator.Annotation

  borderWidth: 2
  borderColour: 'red'

  marker: null

  image: null

  selector: null

  displayMarker: ->
    @marker = jQuery('<span>').appendTo(document)
    imgPosition = @image.position()
    @marker.css(
        position: 'absolute'
        left: imgPosition.left + @selector.x1 + @borderWidth
        top: imgPosition.top + @selector.y1 + @borderWidth
        border: @borderWidth + 'px solid ' + @borderColour
#        zIndex: _n.parent().css('zIndex')
    )
    @marker.width(@selector.width - borderWidth * 2)
    @marker.height(@selector.height - borderWidth * 2);
    @marker.addClass('annotator-hl')

  hideMarker: ->
    @marker?.hide()

