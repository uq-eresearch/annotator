# Public: Prov plugin displays provenance properties for annotation
class Annotator.Plugin.Prov extends Annotator.Plugin
  # Public: Initialises the plugin and adds custom fields to the
  # annotator viewer. The plugin also checks if the annotator is
  # supported by the current browser.
  #
  # Returns nothing.
  pluginInit: ->
    return unless Annotator.supported()
    @annotator.viewer.addField({
      load: this.updateViewer
    })
  # Annotator.Viewer callback function. Updates the annotation display with prov properties
  # removes the field from the Viewer if there are none to display.
  #
  # field      - The Element to populate with provenance properties.
  # annotation - An annotation object to be displayed.
  #
  # Returns nothing.
  updateViewer: (field, annotation) ->
    field = Annotator.$(field)
    console.log("update viewer", annotation, field)
    if annotation.creator || annotation.annotatedAt
      field.addClass('annotator-prov').html('by ' + Annotator.$.escape(annotation.creator))
    else
      field.remove()