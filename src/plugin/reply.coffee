# Public: Reply plugin allows users to create and view replies to an annotation
# requires LoreStore plugin
class Annotator.Plugin.Reply extends Annotator.Plugin
	events:
		"annotationViewerShown": "annotationViewerShown"
		#".annotator-reply click":   "onReplyClick"
		#".annotator-replies-count click": "showReplies"
		#".annotator-link click": "viewAnnotation"

	pluginInit: ->
		return unless Annotator.supported()
		
		@annotator.viewer.addField({
			load: this.updateViewerReplies
			annoPlugin: this
		})
		@annotator.editor.addField({
			load: this.updateEditorInReplyTo
			annoPlugin: this
		})
		
		this.addLocalEvent(@annotator.viewer.element, '.annotator-reply', 'click', 'onReplyClick')
		this.addLocalEvent(@annotator.viewer.element, '.annotator-replies-count', 'click', 'showReplies')
		this.addLocalEvent(@annotator.viewer.element, '.annotator-link', 'click', 'viewAnnotation')

	addLocalEvent: (el, bindTo, event, functionName) ->
		closure = => this[functionName].apply(this, arguments)
		el.on event, bindTo, closure

	# display details of annotation being replied to in editor
	updateEditorInReplyTo: (field,annotation) ->
		if annotation.inReplyTo
			text = Annotator.$.trim(annotation.inReplyTo.text).substring(0, 68).trim(this) + (if annotation.inReplyTo.text.length > 68 then "..." else "");
			Annotator.$(field).attr('readonly',true).addClass('muted').css('padding','2px')
			.html("In reply to '<i>" + text + "</i>'" + (if annotation.inReplyTo.creator then " by " + annotation.inReplyTo.creator else ""))
		else
			Annotator.$(field).remove()

	# display any replies in a field in the viewer
	updateViewerReplies: (field, annotation) ->
		# handler to update replies after replies have been requested
		handleReplies = (result) =>
			if !annotation.replies
				annotation.replies = store.mapAnnotations(result)
			replies = annotation.replies
			replies.sort (a,b) ->
				return a.created > b.created
			if replies.length > 0
				repliescount = Annotator.$("<span class='annotator-replies-count'>" + replies.length + " Repl" + (if replies.length == 1 then "y" else "ies") + "</span>")
				repliescontent = Annotator.$("<div class='annotator-replies-content' style='display:none;padding-top:0.5em'></div>")
				field.html(repliescount)
				field.append(repliescontent)
				replies.forEach (r) ->
					repliescontent.append("<p style='border:1px solid #dedede; padding:3px'><span style='color:#3c3c3c'>" + r.text + "</span><br/>" + (if prov then "<span style='font-size:smaller;'>" + prov.formatProvInfo(r.creator, r.created ) + "</span>" else "") + "</p>")
			else
				field.remove()

		# use the store plugin to request replies
		store = this.annoPlugin.annotator.plugins.LoreStore
		prov = this.annoPlugin.annotator.plugins.Prov
		if !store
			field.remove()
			return
		field = Annotator.$(field)
		# issue search request to retrieve annotations annotating annotation.id
		if annotation.replies
			handleReplies annotation.replies
		else if annotation.id
			# FIXME: should not be calling private store function
			store._apiRequest 'search', {'annotates': annotation.id}, handleReplies

	# add reply button to controls of viewer for creating replies
	annotationViewerShown: (viewer, annotations) ->
		Annotator.$(viewer.element).find('.annotator-controls')
		.append('<button class="annotator-link" title="View">View</button>')
		.append('<button style="background-image: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA0AAAAKCAYAAABv7tTEAAAEJGlDQ1BJQ0MgUHJvZmlsZQAAOBGFVd9v21QUPolvUqQWPyBYR4eKxa9VU1u5GxqtxgZJk6XtShal6dgqJOQ6N4mpGwfb6baqT3uBNwb8AUDZAw9IPCENBmJ72fbAtElThyqqSUh76MQPISbtBVXhu3ZiJ1PEXPX6yznfOec7517bRD1fabWaGVWIlquunc8klZOnFpSeTYrSs9RLA9Sr6U4tkcvNEi7BFffO6+EdigjL7ZHu/k72I796i9zRiSJPwG4VHX0Z+AxRzNRrtksUvwf7+Gm3BtzzHPDTNgQCqwKXfZwSeNHHJz1OIT8JjtAq6xWtCLwGPLzYZi+3YV8DGMiT4VVuG7oiZpGzrZJhcs/hL49xtzH/Dy6bdfTsXYNY+5yluWO4D4neK/ZUvok/17X0HPBLsF+vuUlhfwX4j/rSfAJ4H1H0qZJ9dN7nR19frRTeBt4Fe9FwpwtN+2p1MXscGLHR9SXrmMgjONd1ZxKzpBeA71b4tNhj6JGoyFNp4GHgwUp9qplfmnFW5oTdy7NamcwCI49kv6fN5IAHgD+0rbyoBc3SOjczohbyS1drbq6pQdqumllRC/0ymTtej8gpbbuVwpQfyw66dqEZyxZKxtHpJn+tZnpnEdrYBbueF9qQn93S7HQGGHnYP7w6L+YGHNtd1FJitqPAR+hERCNOFi1i1alKO6RQnjKUxL1GNjwlMsiEhcPLYTEiT9ISbN15OY/jx4SMshe9LaJRpTvHr3C/ybFYP1PZAfwfYrPsMBtnE6SwN9ib7AhLwTrBDgUKcm06FSrTfSj187xPdVQWOk5Q8vxAfSiIUc7Z7xr6zY/+hpqwSyv0I0/QMTRb7RMgBxNodTfSPqdraz/sDjzKBrv4zu2+a2t0/HHzjd2Lbcc2sG7GtsL42K+xLfxtUgI7YHqKlqHK8HbCCXgjHT1cAdMlDetv4FnQ2lLasaOl6vmB0CMmwT/IPszSueHQqv6i/qluqF+oF9TfO2qEGTumJH0qfSv9KH0nfS/9TIp0Wboi/SRdlb6RLgU5u++9nyXYe69fYRPdil1o1WufNSdTTsp75BfllPy8/LI8G7AUuV8ek6fkvfDsCfbNDP0dvRh0CrNqTbV7LfEEGDQPJQadBtfGVMWEq3QWWdufk6ZSNsjG2PQjp3ZcnOWWing6noonSInvi0/Ex+IzAreevPhe+CawpgP1/pMTMDo64G0sTCXIM+KdOnFWRfQKdJvQzV1+Bt8OokmrdtY2yhVX2a+qrykJfMq4Ml3VR4cVzTQVz+UoNne4vcKLoyS+gyKO6EHe+75Fdt0Mbe5bRIf/wjvrVmhbqBN97RD1vxrahvBOfOYzoosH9bq94uejSOQGkVM6sN/7HelL4t10t9F4gPdVzydEOx83Gv+uNxo7XyL/FtFl8z9ZAHF4bBsrEwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAN1JREFUKBV9kTEOAUEUhmfYQtQu4BAKhWjoNOIQLiBxCNFIJDqNUusItDQ6Z1DoROz4/tk3m80WJvny3rz//W9nZ1wIwQlWQ1jeJ59a3kw9KarRee8l5IJ8RukCPWmsjFoDfLFlMrkMX0VYIxxNjAPR3jYwoBdGCurpwhm0yS0+iVfYw0h91huNE4ovkOEDyaR9lV0yxiMg1pea62vO6bax+Od4dxpOoEt5QPrqkNzFK1WEDSRxYQNb1Dowhhsc0s+Vb0FRVy7jykxVrU19GU0mVh93gFg+Lrm0zPqyH71Zj00AB94xAAAAAElFTkSuQmCC);" title="Reply" class="annotator-reply">Reply</button>')
		
	onReplyClick: (event) ->
		item = Annotator.$(event.target).parents('.annotator-annotation')
		anno = item.data('annotation')
		replyPosition = Annotator.$(@annotator.viewer.element).position()
		replyanno = this.setupReply(anno)

		save = =>
			# delete cached replies so that new reply will also be loaded next time anno is viewed
			delete anno.replies
			do cleanup
			# Fire annotationCreated events so that plugins can react to them
			this.publish('annotationCreated', [replyanno])
		cancel = =>
			do cleanup
		cleanup = =>
			this.unsubscribe('annotationEditorHidden', cancel)
			this.unsubscribe('annotationEditorSubmit', save)

		# attach handlers for cancel and save buttons in editor
		this.subscribe('annotationEditorHidden', cancel)
		this.subscribe('annotationEditorSubmit', save)
		@annotator.showEditor(replyanno, replyPosition)

	showReplies: (event) ->
		item = Annotator.$(event.target).parents('.annotator-annotation')
		anno = item.data('annotation')
		item.find('.annotator-replies-content').toggle()

	viewAnnotation: (event) ->
		item = Annotator.$(event.target).parents('.annotator-annotation')
		anno = item.data('annotation')
		window.open("/annotations/search/id?uri=" + encodeURIComponent(anno.id))

	setupReply: (anno) ->
		annotation = 
			uri: anno.id
			text: ""
			inReplyTo: anno
			highlights: []
			motivation: "oa:replying"
		annotation

	

