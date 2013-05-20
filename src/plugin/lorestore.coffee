# Public: The LoreStore plugin can be used to persist annotations to lorestore
class Annotator.Plugin.LoreStore extends Annotator.Plugin
  events:
    'annotationCreated': 'annotationCreated'
    'annotationDeleted': 'annotationDeleted'
    'annotationUpdated': 'annotationUpdated'

  options:
    annotationData: {}
    emulateHTTP: false
    prefix: '/lorestore'
    urls:
      create:  '/oa/'
      read:    ':id'
      update:  ':id'
      destroy: ':id'
      search:  '/oa/'

  # Public: The constructor initialases the LoreStore plugin instance. It requires the
  # Annotator#element and an Object of options.
  #
  # element - This must be the Annotator#element in order to listen for events.
  # options - An Object of key/value user options.
  #
  # Examples
  #
  #   store = new Annotator.Plugin.LoreStore(Annotator.element, {
  #     prefix: '',
  #     annotationData: {
  #       uri: window.location.href
  #     }
  #   })
  #
  # Returns a new instance of LoreStore.
  constructor: (element, options) ->
    super
    @annotations = []

  # Public: Initialises the plugin and loads the latest annotations. If the
  # Auth plugin is also present it will request an auth token before loading
  # any annotations.
  #
  # Examples
  #
  #   store.pluginInit()
  #
  # Returns nothing.
  pluginInit: ->
    return unless Annotator.supported()

    if @annotator.plugins.Auth
      @annotator.plugins.Auth.withToken(this._getAnnotations)
    else
      this._getAnnotations()

  # Loads annotations
  #
  # Returns nothing.
  _getAnnotations: =>
      this.loadAnnotationsFromSearch()


  # Public: Callback method for annotationCreated event. Receives an annotation
  # and sends a POST request to the sever using the URI for the "create" action.
  #
  # annotation - An annotation Object that was created.
  #
  # Examples
  #
  #   store.annotationCreated({text: "my new annotation comment"})
  #   # => Results in an HTTP POST request to the server containing the
  #   #    annotation as serialised JSON.
  #
  # Returns nothing.
  annotationCreated: (annotation) ->
    # Pre-register the annotation so as to save the list of highlight
    # elements.
    if annotation not in @annotations
      this.registerAnnotation(annotation)

      this._apiRequest('create', annotation, (data) =>
        # Update with ID from server
        anno = this._findAnnos(data['@graph'])[0]
        id = anno['@id']
        created = anno.annotatedAt
        creator = anno.annotatedBy
        if (creator)
          creator = this._findById(data['@graph'], creator)
          if (creator && creator.name)
            creator = creator.name
        if (created)
          created = created['@value']
        if not id?
          console.warn Annotator._t("Warning: No ID returned from server for annotation "), annotation
        this.updateAnnotation annotation, {'id': id, 'created': created, 'creator': creator}
      )
    else
      # This is called to update annotations created at load time with
      # the highlight elements created by Annotator.
      this.updateAnnotation annotation, {}

  # Public: Callback method for annotationUpdated event. Receives an annotation
  # and sends a PUT request to the sever using the URI for the "update" action.
  #
  # annotation - An annotation Object that was updated.
  #
  # Examples
  #
  #   store.annotationUpdated({id: "blah", text: "updated annotation comment"})
  #   # => Results in an HTTP PUT request to the server containing the
  #   #    annotation as serialised JSON.
  #
  # Returns nothing.
  annotationUpdated: (annotation) ->
    if annotation in this.annotations
      #'id': this._findAnnos(data['@graph'])[0]['@id']
      this._apiRequest 'update', annotation, ((data) => this.updateAnnotation(annotation, {}))

  # Public: Callback method for annotationDeleted event. Receives an annotation
  # and sends a DELETE request to the server using the URI for the destroy
  # action.
  #
  # annotation - An annotation Object that was deleted.
  #
  # Examples
  #
  #   store.annotationDeleted({text: "my new annotation comment"})
  #   # => Results in an HTTP DELETE request to the server.
  #
  # Returns nothing.
  annotationDeleted: (annotation) ->
    if annotation in this.annotations
      this._apiRequest 'destroy', annotation, (() => this.unregisterAnnotation(annotation))

  # Public: Registers an annotation with the LoreStore. Used to check whether an
  # annotation has already been created when using LoreStore#annotationCreated().
  #
  # NB: registerAnnotation and unregisterAnnotation do no error-checking/
  # duplication avoidance of their own. Use with care.
  #
  # annotation - An annotation Object to resister.
  #
  # Examples
  #
  #   store.registerAnnotation({id: "annotation"})
  #
  # Returns registed annotations.
  registerAnnotation: (annotation) ->
    @annotations.push(annotation)

  # Public: Unregisters an annotation with the LoreStore.
  #
  # NB: registerAnnotation and unregisterAnnotation do no error-checking/
  # duplication avoidance of their own. Use with care.
  #
  # annotation - An annotation Object to unresister.
  #
  # Examples
  #
  #   store.unregisterAnnotation({id: "annotation"})
  #
  # Returns remaining registed annotations.
  unregisterAnnotation: (annotation) ->
    @annotations.splice(@annotations.indexOf(annotation), 1)

  # Public: Extends the provided annotation with properties from the data
  # Object. Will only extend annotations that have been registered with the
  # store. Also updates the annotation object stored in the 'annotation' data
  # store.
  #
  # annotation - An annotation Object to extend.
  # data       - An Object containing properties to add to the annotation.
  #
  # Examples
  #
  #   annotation = $('.annotation-hl:first').data('annotation')
  #   store.updateAnnotation(annotation, {extraProperty: "bacon sarnie"})
  #   console.log($('.annotation-hl:first').data('annotation').extraProperty)
  #   # => Outputs "bacon sarnie"
  #
  # Returns nothing.
  updateAnnotation: (annotation, data) ->
    if annotation not in this.annotations
      console.error Annotator._t("Trying to update unregistered annotation!")
    else
      jQuery.extend(annotation, data)

    # Update the elements with our copies of the annotation objects (e.g.
    # with ids from the server).
    jQuery(annotation.highlights).data('annotation', annotation)

  # map OA results into internal annotator format
  mapAnnotations: (data={}) =>
    annotations = []
    annos = this._findAnnos(data['@graph'])
    for anno in annos
      body = this._findById(data['@graph'], anno['hasBody'])
      target = this._findById(data['@graph'], anno['hasTarget'])
      targetsel = this._findById(data['@graph'],target['hasSelector'])
      tempanno = {
        "id" : anno['@id']
        "text": body.chars
        "ranges": []
        "motivation": anno.motivatedBy
      }
      if anno.annotatedBy
        creator = this._findById(data['@graph'], anno.annotatedBy)
        if creator
          tempanno.annotatedBy = anno.annotatedBy
          tempanno.creator = creator.name
      if anno.annotatedAt
        tempanno.created = anno.annotatedAt['@value']
      if targetsel && targetsel['@type']=='oa:Choice'
        textQuoteSelector = this._findById(data['@graph'], targetsel.default)
        tempanno.quote = textQuoteSelector.exact
        tempanno.prefix = textQuoteSelector.prefix
        tempanno.suffix = textQuoteSelector.suffix

        processSelector = (sel) ->
          switch sel['@type']
            when 'austese:RangeSelector'
              tempanno.ranges = [
                {
                  "start": sel["lorestore:startElement"]
                  "startOffset": sel["lorestore:startOffset"]
                  "end": sel["lorestore:endElement"]
                  "endOffset": sel["lorestore:endOffset"]
                }
              ]
            when 'oa:TextPositionSelector'
              tempanno.startOffset = sel['start']
              tempanno.endOffset = sel['end']
        if typeof targetsel.item == 'string'
          selector = this._findById(data['@graph'], targetsel.item)
          processSelector(selector)
        else if typeof targetsel.item =='object'
          selectors = (this._findById(data['@graph'], id) for id in targetsel.item)
          processSelector(selector) for selector in selectors
      else if targetsel && targetsel.value && targetsel.value.match("xywh=")
        image = jQuery("[data-id='" + target.hasSource + "']").find('img')
        if image.length > 0
          image = image[0]
        selectiondata = targetsel.value.split("=")[1].split(",")
        tempanno.relativeSelection = 
          "x1": parseFloat(selectiondata[0])
          "y1": parseFloat(selectiondata[1])
          "x2": parseFloat(selectiondata[0]) + parseFloat(selectiondata[2])
          "y2": parseFloat(selectiondata[1]) + parseFloat(selectiondata[3])
          "width": parseFloat(selectiondata[2])
          "height": parseFloat(selectiondata[3])
          "image": image

      annotations.push tempanno
    # return annotations
    annotations

  # Callback method for LoreStore#loadAnnotationsFromSearch(). Processes the data
  # returned from the server (a JSON array of annotation Objects) and updates
  # the registry as well as loading them into the Annotator.
  #
  # data - An Array of annotation Objects
  #
  # Examples
  #
  #   console.log @annotation # => []
  #   store._onLoadAnnotations([{}, {}, {}])
  #   console.log @annotation # => [{}, {}, {}]
  #
  # Returns nothing.
  _onLoadAnnotations: (data={}) =>
    @loads--
    @annotations = this.mapAnnotations(data)
    if(@loads == 0)
      #console.log("annotator load annotations",data,@annotations)
      @annotator.loadAnnotations(@annotations.slice()) # Clone array

  # Public: Performs the same task as LoreStore.#loadAnnotations() but calls the
  # 'search' URI with an optional query string.
  #
  # searchOptions - Object literal of query string parameters.
  #
  # Examples
  #
  #   store.loadAnnotationsFromSearch({
  #     limit: 100,
  #     uri: window.location.href
  #   })
  #
  # Returns nothing.
  loadAnnotationsFromSearch: (searchOptions) ->
    @annotations = []
    @loads = 0;
    embedded = false
    # search for annotations on embedded resources, if there is a data-id attribute use that
    jQuery(@element).find('[data-id]').andSelf().each (index, el) =>
      id = jQuery(el).data('id')
      if (id)
        embedded = true
        @loads++
        this._apiRequest 'search', {'annotates': id}, this._onLoadAnnotations
    if !embedded
      # otherwise, use search options to search using annotates parameter (or uri for compatibility with Annotator store)
      if !searchOptions
        searchOptions = {}
      if !searchOptions.annotates
        searchOptions.annotates = searchOptions.uri || document.location.href 
      this._apiRequest 'search', searchOptions, this._onLoadAnnotations


  # Public: Dump an array of serialized annotations
  #
  # param - comment
  #
  # Examples
  #
  #   example
  #
  # Returns
  dumpAnnotations: ->
    (JSON.parse(this._dataFor(ann)) for ann in @annotations)

  # Processes the data
  # returned from the server (a JSON array of annotation Objects) and updates
  # the registry as well as loading them into the Annotator.
  # Returns the jQuery XMLHttpRequest wrapper enabling additional callbacks to
  # be applied as well as custom error handling.
  #
  # action    - The action String eg. "read", "search", "create", "update"
  #             or "destory".
  # obj       - The data to be sent, either annotation object or query string.
  # onSuccess - A callback Function to call on successful request.
  #
  # Examples:
  #
  #   store._apiRequest('read', {id: 4}, (data) -> console.log(data))
  #   # => Outputs the annotation returned from the server.
  #
  # Returns jXMLHttpRequest object.
  _apiRequest: (action, obj, onSuccess) ->
    id  = obj && obj.id
    resourceuri = obj && obj.resourceuri
    url = this._urlFor(action, id, resourceuri)
    options = this._apiRequestOptions(action, obj, onSuccess)

    request = jQuery.ajax(url, options)

    # Append the id and action to the request object
    # for use in the error callback.
    request._id = id
    request._action = action
    request

  # Builds an options object suitable for use in a jQuery.ajax() call.
  #
  # action    - The action String eg. "read", "search", "create", "update"
  #             or "destory".
  # obj       - The data to be sent, either annotation object or query string.
  # onSuccess - A callback Function to call on successful request.
  #
  # Also extracts any custom headers from data stored on the Annotator#element
  # under the 'annotator:headers' key. These headers should be stored as key/
  # value pairs and will be sent with every request.
  #
  # Examples
  #
  #   annotator.element.data('annotator:headers', {
  #     'X-My-Custom-Header': 'CustomValue',
  #     'X-Auth-User-Id': 'bill'
  #   })
  #
  # Returns Object literal of $.ajax() options.
  _apiRequestOptions: (action, obj, onSuccess) ->
    method = this._methodFor(action)

    opts = {
      type:       method,
      headers:    @element.data('annotator:headers'),
      dataType:   "json",
      headers:    {'Accept':'application/json', 'Content-Type': 'application/json'},
      success:    (onSuccess or ->),
      error:      this._onError
    }

    # If emulateHTTP is enabled, we send a POST and put the real method in an
    # HTTP request header.
    if @options.emulateHTTP and method in ['PUT', 'DELETE']
      opts.headers = jQuery.extend(opts.headers, {'X-HTTP-Method-Override': method})
      opts.type = 'POST'

    # Don't JSONify obj if making search request.
    if action is "search"
      opts = jQuery.extend(opts, data: obj)
      return opts

    data = obj && this._dataFor(obj)

    # If emulateJSON is enabled, we send a form request (the correct
    # contentType will be set automatically by jQuery), and put the
    # JSON-encoded payload in the "json" key.
    if @options.emulateJSON
      opts.data = {json: data}
      if @options.emulateHTTP
        opts.data._method = method
      return opts

    opts = jQuery.extend(opts, {
      data: data
      contentType: "application/json; charset=utf-8"
    })
    return opts

  # Builds the appropriate URL from the options for the action provided.
  #
  # action - The action String.
  # id     - The annotation id as a String or Number.
  #
  # Examples
  #
  #   store._urlFor('update', 34)
  #   # => Returns "/store/annotations/34"
  #
  #   store._urlFor('search')
  #   # => Returns "/store/search"
  #
  # Returns URL String.
  _urlFor: (action, id, resourceuri) ->
    if action != 'read' && action != 'search' && action != 'create'
      url = id
    else
      url = if @options.prefix? then @options.prefix else ''
      url += @options.urls[action]
      url = url.replace(/:resourceuri/, if resourceuri then encodeURIComponent(resourceuri) else encodeURIComponent(document.location.href))
    url

  # Maps an action to an HTTP method.
  #
  # action - The action String.
  #
  # Examples
  #
  #   store._methodFor('read')    # => "GET"
  #   store._methodFor('update')  # => "PUT"
  #   store._methodFor('destroy') # => "DELETE"
  #
  # Returns HTTP method String.
  _methodFor: (action) ->
    table = {
      'create':  'POST'
      'read':    'GET'
      'update':  'PUT'
      'destroy': 'DELETE'
      'search':  'GET'
    }

    table[action]

  # Creates a JSON serialisation of an annotation.
  #
  # annotation - An annotation Object to serialise.
  #
  # Examples
  #
  #   store._dataFor({id: 32, text: 'my annotation comment'})
  #   # => Returns '{"id": 32, "text":"my annotation comment"}'
  #
  # Returns
  _dataFor: (annotation) ->

    # Preload with extra data.
    jQuery.extend(annotation, @options.annotationData)
    
    bodysrid = 'urn:uuid:' + this._uuid()
    

    if annotation.uri
      # first check whether a uri is explicitly set in annotation data (e.g. by another plugin such as the reply plugin)
      targeturi = annotation.uri
    else if @element.data('id') 
      # in AustESE we apply annotations to elements with data-id attr that identifies the underlying target object
      # i.e. a transcription, image or entity identified by a URI
      targeturi = @element.data('id') 
    else 
      # fall back to using the URI of the current page
      targeturi = document.location.href

    # check whether annotation data includes selection, to determine whether the target is the resource URI or a URN identifying a specific target
    if (annotation.quote || annotation.relativeSelection)
      targetsrid = 'urn:uuid:' + this._uuid()
    else
      targetsrid = targeturi

    tempanno = {
      '@context':
        "oa": "http://www.w3.org/ns/oa#"
        "dc": "http://purl.org/dc/elements/1.1/"
        "cnt": "http://www.w3.org/2011/content#"
        "lorestore": "http://auselit.metadata.net/lorestore/"
        "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        "austese": "http://austese.net/ns/oa/"
      '@graph': [
        {
          '@id': if annotation.id then annotation.id else 'http://example.org/dummy'
          '@type': 'oa:Annotation'
          'oa:hasBody': 
            '@id': bodysrid
          'oa:hasTarget':
            '@id': targetsrid
        },{
          '@id': bodysrid
          '@type': 'cnt:ContentAsText'
          'cnt:chars': annotation.text
          'dc:format': 'text/plain' 
        }
      ]
    }
    # check for creator and created - lorestore inserts prov info for new annotations but expects it to be preserved in updates
    if annotation.annotatedBy
      tempanno['@graph'][0]['oa:annotatedBy'] = {'@id': annotation.annotatedBy}
      agent = {
        '@id': annotation.annotatedBy
        'foaf:name': annotation.creator
      }
      tempanno['@graph'].push agent
    if annotation.created
      tempanno['@graph'][0]['oa:annotatedAt'] = {'@value': annotation.created, '@type': 'dcterms:W3CDTF'}

    # check for motivation
    if annotation.motivation
      tempanno['@graph'][0]['oa:motivatedBy'] = {'@id': annotation.motivation}

    # add specific target if required
    if (annotation.quote || annotation.relativeSelection)
      targetselid = 'urn:uuid:' + this._uuid()
      specifictarget = {
        '@id': targetsrid
        '@type': 'oa:SpecificResource'
        'oa:hasSource':  
          '@id': targeturi
        'oa:hasSelector':
           '@id': targetselid
      }
      tempanno['@graph'].push specifictarget

    # add selector for target if required
    if annotation.quote
      # text annotation
      targetselector = 
        '@id': targetselid
        '@type': 'oa:Choice'
        'oa:item': [
          {
            '@id': 'urn:uuid:' + this._uuid()
            '@type': 'austese:RangeSelector'
            # store a direct copy of the annotator text range data for now
            'lorestore:startOffset': annotation.ranges[0].startOffset
            'lorestore:endOffset': annotation.ranges[0].endOffset
            'lorestore:startElement': annotation.ranges[0].start
            'lorestore:endElement': annotation.ranges[0].end
          },{
            '@id': 'urn:uuid:' + this._uuid()
            '@type': 'oa:TextPositionSelector'
            'oa:start': annotation.startOffset
            'oa:end': annotation.endOffset
          }
        ]
        'oa:default': 
          '@type': 'oa:TextQuoteSelector'
          '@id': 'urn:uuid:' + this._uuid()
          'oa:exact': annotation.quote
          'oa:prefix': annotation.prefix
          'oa:suffix': annotation.suffix
    else if annotation.relativeSelection
      # image annotation
      targetselector = 
        '@id': targetselid
        '@type': 'oa:FragmentSelector'
        'rdf:value': 'xywh=' + annotation.relativeSelection.x1 + ',' + annotation.relativeSelection.y1 + ',' + annotation.relativeSelection.width + ',' + annotation.relativeSelection.height
    tempanno['@graph'].push targetselector

    data = JSON.stringify(tempanno)
    #console.log("dataFor",data)
    data

  # jQuery.ajax() callback. Displays an error notification to the user if
  # the request failed.
  #
  # xhr - The jXMLHttpRequest object.
  #
  # Returns nothing.
  _onError: (xhr) =>
    action  = xhr._action
    message = Annotator._t("Unable to ") + action + Annotator._t(" this annotation")

    if xhr._action == 'search'
      message = Annotator._t("Unable to search the store for annotations")
    else if xhr._action == 'read' && !xhr._id
      message = Annotator._t("Unable to ") + action + Annotator._t(" the annotations from the store")

    switch xhr.status
      when 401 then message = Annotator._t("Sorry you are not allowed to ") + action + Annotator._t(" this annotation")
      when 404 then message = Annotator._t("Unable to connect to the annotations store")
      when 500 then message = Annotator._t("Something went wrong with the annotation store")

    Annotator.showNotification message, Annotator.Notification.ERROR

    console.error Annotator._t("API request failed:") + " '#{xhr.status}'"

  # find the OA annotation object in a JSON-LD graph
  _findAnnos: (graph) =>
    found = []
    for obj in graph
      if obj['@type'] == 'oa:Annotation'
        found.push obj
    found

  # find an object by id in a JSON-LD graph
  _findById: (graph, id) =>
    for obj in graph
      if obj['@id'] == id
        found = obj
        break
    found

  # generate a UUID (used for inline bodies etc)
  # from https://gist.github.com/1893440
  _uuid: =>
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
      r = Math.random() * 16 | 0
      v = if c is 'x' then r else (r & 0x3|0x8)
      v.toString(16)
      )
