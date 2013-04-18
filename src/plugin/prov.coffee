# Public: Prov plugin displays provenance properties for annotation
# requires jQuery timeago http://timeago.yarp.com/
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
    if annotation.creator || annotation.created
      field.addClass('annotator-prov').html(
        (if annotation.creator then 'by ' + Annotator.$.escape(annotation.creator) + ", " else "") + 
        (if annotation.created then jQuery.timeago(new Date(Annotator.$.escape(annotation.created))) else "")
      )
    else
      field.remove()