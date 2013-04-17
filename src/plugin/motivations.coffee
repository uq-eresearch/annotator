# Public: Motivations plugin allows users to select a Motivation
class Annotator.Plugin.Motivations extends Annotator.Plugin
  options:
    motivations: 
      [
        {
          value: "http://austese.net/ns/oa/TextualNote" 
          label: "Textual Note"
        },
        {
          value: "http://austese.net/ns/oa/ExplanatoryNote" 
          label: "Explanatory Note"
        },
        {
          value: "http://austese.net/ns/oa/HistoricalNote" 
          label: "Historical Note"
        },
        {
          value: "http://austese.net/ns/oa/BiographicalNote" 
          label: "Biographical Note"
        },
        {
          value: "http://austese.net/ns/oa/Glossary" 
          label: "Glossary"
        },
        {
          value: "http://austese.net/ns/oa/ClassicalAllusion" 
          label: "Classical Allusion"
        },
        {
          value: "http://austese.net/ns/oa/BiblicalAllusion" 
          label: "Biblical Allusion"
        }
      ]
  # The field element added to the Annotator.Editor wrapped in jQuery. Cached to
  # save having to recreate it everytime the editor is displayed.
  field: null

  # The input element added to the Annotator.Editor wrapped in jQuery. Cached to
  # save having to recreate it everytime the editor is displayed.
  input: null

  # Public: Initialises the plugin and adds custom fields to both the
  # annotator viewer and editor. The plugin also checks if the annotator is
  # supported by the current browser.
  #
  # Returns nothing.
  pluginInit: ->
    return unless Annotator.supported()
    # todo config for motivations (read from options)
  
    @field = @annotator.editor.addField({
      label:  Annotator._t('ExplanatoryNote')
      load:   this.updateField
      submit: this.setAnnotationMotivations
    })
    # replace default input created by editor with a select field
    id = Annotator.$(@field).find('input').attr('id')
    select = '<li class="annotator-item"><select style="width:100%"><option value="">(Uncategorised)</option>'
    for m in @options.motivations
      select += '<option value="' + m.value + '">' + m.label + '</option>'
    select += '</select></li>'
    newfield = Annotator.$(select)
    Annotator.$(@field).replaceWith(newfield)
    @field=newfield[0]

    
    @annotator.viewer.addField({
      load: this.updateViewer
      annoPlugin: this
    })

    @input = Annotator.$(@field).find('select')


  # Annotator.Editor callback function. Updates the @input field with the
  # Motivation attached to the provided annotation.
  #
  # Returns nothing.
  updateField: (field, annotation) =>
    value = ''
    value = annotation.motivation if annotation.motivation

    @input.val(value)

  # Annotator.Editor callback function. Updates the annotation field with the
  # data retrieved from the @input property.
  #
  # field      - The Motivation field Element containing the input Element.
  # annotation - An annotation object to be updated.
  # Returns nothing.
  setAnnotationMotivations: (field, annotation) =>
    annotation.motivation = @input.val()

  # Annotator.Viewer callback function. Updates the annotation display with Motivations
  # removes the field from the Viewer if there are no Motivations to display.
  #
  # field      - The Element to populate with Motivations.
  # annotation - An annotation object to be display.
  #
  # Returns nothing.
  updateViewer: (field, annotation) ->
    field = Annotator.$(field)
    if annotation.motivation 
      displayValue = annotation.motivation
      for m in this.annoPlugin.options.motivations
        if m.value == annotation.motivation
          displayValue = m.label
      field.addClass('annotator-motivation').html('<span class="annotator-motivation">' + Annotator.$.escape(displayValue) + '</span>')
    else
      field.remove()

