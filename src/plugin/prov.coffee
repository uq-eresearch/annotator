class Annotator.Plugin.Prov extends Annotator.Plugin
    
    pluginInit: ->
        return unless Annotator.supported()
        @annotator.viewer.addField({
            load: this.updateViewer
        })

    updateViewer: (field, annotation) ->
        field = Annotator.$(field)
        console.log("update viewer", annotation, field)
        if annotation.creator || annotation.annotatedAt
            field.addClass('annotator-prov').html('by ' + Annotator.$.escape(annotation.creator))
        else
            field.remove()