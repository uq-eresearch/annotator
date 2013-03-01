# Possible Libraries
# https://github.com/flipbit/jquery-image-annotate
# http://odyniec.net/projects/imgareaselect/
# http://deepliquid.com/content/Jcrop.html


# Public: Image region plugin allows users to select a region in
# an image as the target of the annotation.
class Annotator.Plugin.Image extends Annotator.Plugin


  # Public: Initialises the plugin
  pluginInit: ->
    # Add image area select to all the appropriate images
    # @element.find('img').imgAreaSelect({
    #     handle: true,
    #     onSelectEnd: this.onNewSelection
    #     })

    # Add this plugin as a handler for annotations with an
    # 'image' target
    @annotator.addAnnotationPlugin this

    # with a callback to creating an image annotation


    # Setup listeners to show existing annotations
    this._setupListeners()

  _onNewSelection: (img, selection) =>
    @annotator.adder.css().show()

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
