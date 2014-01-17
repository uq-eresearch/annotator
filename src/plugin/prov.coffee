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
      annoPlugin: this
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
      field.addClass('annotator-prov').html('<span class="annotator-motivation"></span>' +
        this.annoPlugin.formatProvInfo(annotation.creator,annotation.created)
      )
    else
      field.remove()

  formatProvInfo: (creator, created) ->
    return (if creator then 'by ' + Util.escape(creator) + ", " else "") + 
        (if created then jQuery.timeago(new Date(Util.escape(created))) else "")