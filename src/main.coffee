# if x is a function, evaluates it, otherwise returns it
# does so recursively until x is not a function anymore
result = (x, args, context) ->
  if x && x.call
    result(x.call(context || @, args), args, context)
  else
    x


DEFER = '__defer'
# marks a function as DEFERred and returns it
defer = (f) ->
  f[DEFER] = 1
  f


# tests whether a function is deferred
is_deferred = (f) ->
  !!f[DEFER]


# identical to result except that if x is a function and x[DEFER] is true,
# x does not get evaluated and is returned as-is
result_defer = (x, args, context) ->
  x && x.call && !x[DEFER] && result(x, args, context) || x


# returns the last element of an array
last = (array) ->
  array.slice(-1)[0]


# pushes an element at the end of an array
push = (array, element) ->
  array.push element


# escape HTML
escape_html = (string) ->
 entities =
    "&": "&amp;"
    "<": "&lt;"
    ">": "&gt;"
    '"': '&quot;'
    "'": '&#39;'
    "/": '&#x2F;'
  String(string).replace /[&<>"'\/]/g, (s) -> entities[s]


# all HTML tags
# TODO: !DOCTYPE
HTML_NONVOID_TAGS = 'a abbr acronym address applet article aside audio b basefont bdi bdo big blockquote body button canvas caption center cite code colgroup command datalist dd del details dfn dialog dir div dl dt em fieldset figcaption figure font footer form frame frameset h1 head header html i iframe ins kbd label legend li map mark menu meta meter nav noframes noscript object ol optgroup option output p pre progress q rp rt ruby s samp script section select small span strike strong style sub summary sup table tbody td textarea tfoot th thead time title tr tt u ul var video'.split(' ')

# http://www.w3.org/html/wg/drafts/html/master/syntax.html#void-elements

# void tags are always self-closing
HTML_VOID_TAGS = 'area base br col embed hr img input keygen link menuitem meta param source track wbr'.split(' ')


# constructor takes Underscore/Lodash as an argument
constructor = (_) ->

  # alias frequently used _ functions
  is_array = _.isArray
  is_string = _.isString
  is_function = _.isFunction
  is_number = _.isNumber
  is_plain_object = _.isPlainObject
  each = _.each
  map = _.map


  # hash to quickly check whether a HTML tag is void
  IS_VOID = {}
  each HTML_VOID_TAGS, (tag) -> IS_VOID[tag] = 1


  # whether a variable is "stringifyable"
  stringifyable = (x) ->
    is_string(x) || is_number(x)


  # push element at the back of array, joining with separator if both
  # the element being added and the last element of the array are
  # stringify-able
  # null or undefined elements are ignored
  # returns the modified array
  push_joining = (array, el, sep = '') ->
    # helper function to push a single element into the array
    _push_joining = (e) ->
      stringifyable_e = stringifyable(e)
      if e? && (!stringifyable_e || (e + '').length)
        if array.length && stringifyable(last(array)) && stringifyable_e
          # concatenate element with the last element of the array
          array[array.length - 1] += ('' + e)
        else
          # push element at the end of the array
          push array, e
      # return the array
      array
    # push the separator
    _push_joining sep if array.length
    # push the actual element and return array
    _push_joining el


  # at the most basic level, a template is an Array of either strings or
  # functions
  # Therefore, evaluating a template means calling all the functions with
  # the template data, and joining the results
  #
  evaluate = (template_array, template_data, context) ->
    map(template_array, (x) ->
      result(x, template_data, context)).join ''


  # concatenates arrays, appending all elements to the first array, which
  # is modified and finally returned.
  # Consecutive stringify-able elements will be joined.
  # all arrays are assumed to be flat. Only allowed elements are
  # functions and stringify-able values
  concat_joining = (arrays...) ->
    buf = arrays.shift() ? []
    each arrays, (array) ->
      each array, (el) ->
        push_joining buf, el, ''
    buf


  # inserts separator between elements of array
  join = (array, sep) ->
    buf = []
    each array, (el, i) ->
      push_joining buf, el, (i == 0 && '' || sep)
    buf


  # flattens attributes
  # The returned Array will only contain Strings and deferred functions.
  flatten_tree_attr = (tree) ->
    buf = []
    acc_buf = {}
    uniq_buf = {}
    # iterates on key-value pairs
    each_pair = (object, callback) ->
      _(object).keys().each (k) ->
        callback k, object[k]
    # from a deep-nested object {a: {b: {c: 1}}}, returns a new object
    # where the paths have been flattened: {a-b-c: 1}
    # TODO : restore this!
    #flatten_object = (object, sep, path) ->
    #  flat = {}
    #  flatten = (obj, path) ->
    #    each_pair obj, (k, v) ->
    #      v = result_defer v
    #      if is_plain_object(v)
    #        flatten(v, path.concat([k]))
    #      else if stringifyable(v) || deferred(v)
    #        flat[path.join(sep)] = v
    #      else
    #        throw "unexpected #{typeof v} in nested Object"
    #  flatten(object, path || [])
    #  flat
    # adds a key-value pair to the buffer
    add_pair_to_buffer = (k, v, vsep) ->
      concat_joining buf, [' ', k, '="']
      concat_joining buf, _.flatten([v]), vsep
      push_joining buf, '"'
    # at the first level, we're expecting Objects or functions
    each tree, (el) ->
      el = result_defer(el)
      if is_array(el)
        throw "unexpected Array #{el} in attributes"
      else if is_plain_object(el)
        # plain object
        each_pair el, (k, v) ->
          v = result_defer v
          if k in ['style', 'class']
            # style: ['s1', 's2'] or class: ['c1', 'c2']
            acc_buf[k] ?= []
            acc_buf[k] = acc_buf[k].concat(_.flatten([v]))
          # TODO: restore this!
          #else if k in ['data'] && is_plain_object(v)
          #  # data: {a: 1, b: 2}
          #  each_pair flatten_object(v, '-', ['data']), add_pair_to_buffer
          else if stringifyable(v) || deferred(v)
            uniq_buf[k] = v
      else
        # function or stringifyable value: add to buffer, space-separated
        push_joining buf, el, ' '
    # add id first if any
    if uniq_buf[k = 'id']
      add_pair_to_buffer k, uniq_buf[k]
    # add accumulated parameters
    each_pair acc_buf, (k, v) ->
      vsep = {style: ';'}[k] || ' '
      add_pair_to_buffer k, join(map(v, result_defer), vsep)
    # add unique parameters
    each_pair uniq_buf, (k, v) ->
      add_pair_to_buffer k, v unless k is 'id'
    # return buffer
    buf


  # takes an Array of Arrays representing the content, and flattens them
  # to a flat array, joining consecutive stringify-able elements whenever
  # possible.
  # The tree is an Array which can contain either functions, stringifyable
  # types, or nested Arrays containing the same types. No Objects are
  # allowed there.
  # The returned Array will only contain Strings and deferred functions.
  flatten_tree_cont = (tree) ->
    buf = []
    each tree, (el) ->
      if is_array(el)
        concat_joining buf, flatten_tree_cont(el)
      else if stringifyable(el) || is_function(el)
        push_joining buf, result_defer(el)
      else
        throw "unexpected #{typeof el} '#{el}' in node content"
    buf


  # takes a tag name, a Tree representing Attributes, and a Tree
  # representing Content, and returns a flat array representing the tag's
  # HTML.
  # The returned Array will only contain Strings and deferred functions.
  flatten_tree_tag = (name, tree_attr, tree_cont) ->
    buf = ['<']
    # function to process the content (depending on whether the tag is
    # a void tag or not)
    process_content = (_buf, resolved_name) ->
      # join tag name and attributes
      concat_joining _buf, [resolved_name], flatten_tree_attr(tree_attr)
      # see if tag is void
      if IS_VOID[resolved_name]
        # tag is void: close it
        push_joining _buf, '/>'
      else
        # tag is not void: turn content into flat array and join it
        concat_joining _buf, ['>'], flatten_tree_cont(tree_cont),
          ['</', resolved_name, '>']
    # see if the tag name is a deferred function
    if is_deferred(name = result_defer(name))
      # the name is a deferred function: resolve it at evaluation time,
      # then evaluate the content and return a string completing the tag
      push buf, defer (template_data, context) ->
        evaluate process_content([], result(name, template_data, context))
    else
      # the name is known: resolve the rest of the tag immediately
      process_content buf, name
    # return the array representation of the Tag
    buf


  # arg 0 is converted to an Object if it is a string representing
  # a CSS class name, an HTML id, or both
  # all Object args are considered part of Attributes
  # all other args are considered part of Content
  normalize = (args) ->
    nf = [[], []]
    # handle special case of args[0]
    if is_string(arg = args[0])
      attr = {}
      if (id = arg.match(/\#(-?[_a-zA-Z]+[_a-zA-Z0-9-]*)/g)?[0])
        attr.id = id.slice(1)
      if (classes = arg.match(/\.(-?[_a-zA-Z]+[_a-zA-Z0-9-]*)/g))
        attr.class = map classes, (x) -> x.slice(1)
      if attr.id || attr.class
        push nf[0], attr
        args.shift()
    # handle all other arguments
    each args, (arg) ->
      if is_plain_object(arg) then push nf[0], arg else push nf[1], arg
    # return normalized
    nf


  # given a path x.y.z and an object {x: {y: {z: V}}, returns the value V
  # nested under the specified path
  get_at_path = (path, object) ->
    resolve = (o, p) ->
      return undefined if !o?
      return o[p[0]] if p.length == 1
      resolve(o[p.shift()], p)
    resolve object, path.split('.')


  T = {}

  # main method to generate the template for an HTML tag
  # caches the Array form under `template_array`, and returns a function
  # which evaluates the `template_array` with the `template_data`
  T.tag = (name, args...) ->
    nf = normalize args
    template_array = flatten_tree_tag name, nf[0], nf[1]
    #console.log 'array', template_array # <- inspect cached template
    defer (template_data) ->
      evaluate template_array, template_data

  # attach tag helpers for all HTML tags
  each HTML_VOID_TAGS.concat(HTML_NONVOID_TAGS), (tagname) ->
    T[tagname] = (args...) -> T.tag tagname, args...

  # shorthands for common HTML tags
  T.d = T.div
  T.btn = T.button

  # map function
  T.$map = T.$m = (array, f) ->
    array = result_defer array
    g = (template_data) ->
      evaluate map(result(array, template_data), f), template_data
    if is_deferred(array) then defer g else g

  # variable placeholder
  T.$var = T.$v = (path, html_safe) ->
    defer (template_data) ->
      value = get_at_path path, template_data
      !html_safe && is_string(value) && escape_html(value) || value

  # scope selector
  T.$with = T.$w = (path, template) ->
    defer (template_data) ->
      template(get_at_path(path, template_data))

  # function placeholder
  T.$fun = T.$f = (f) ->
    defer (template_data) ->
      f.call(@, template_data)

  # magic closure wrapper
  T.$closure = T.$c = (names, f, context) ->
    f.apply context ? @, map(names.split(' '), (n) -> T[n])

  # return main object T
  T

# if AMD, define as a module with `lodash` dependency
(typeof define == 'function') && define.amd && define('templebar',
  ['lodash'], constructor)

# export constructor function and return it
return (typeof module != 'undefined') && (module.exports = constructor) ||
  constructor