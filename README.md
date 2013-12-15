# Templebar

---

Templebar is a compact and fast templating engine for Javascript and
Coffeescript.

It has a concise and intuitive syntax inspired by [HAML](http://haml.info/),
weighs only 4KB (uncompressed), and lets you write good-looking templates that behave nicely when minified.


## Usage

Templebar currently requires [Lodash](http://lodash.com/) and an
AMD loader such as [Requirejs](http://requirejs.org/).

Just grab the minified JS from this repository, bundle it with your app,
and `require` it (it will look for a module named `"lodash"`):

    T = require('templebar')

> A standalone (no-Lodash) version, and a "ugly-global-variable" (no-AMD)
> version may be released soon.


## Example

With Templebar, you can define your template like this (in CoffeeScript):

    template =
      T.d '#main.container',
        T.p style: ['margin:10px 0', 'font-weight:bold'],
          T.btn '.btn', {class: T.$v('class')}, T.$v('label')

Then you call the `template` function with your parameters...

    template(class: 'success', label: 'Click')

...and you get the following HTML (indentation added for readability):

    <div id="main" class="container">
      <p style="margin:10px 0;font-weight:bold">
        <button class="btn success">Click</button>
      </p>
    </div>

That's it: no precompilation, no ugly heavy HTML strings all over your code. The HTML is generated when the template is initialized, cached, and
intelligently interpolated every time the template is invoked.

The above CoffeeScript code, when compiled to Javascript and minified,
is just 125 characters long...

    T.d("#main.container",T.p({style:["margin:10px 0","font-weight:bold"]},
    T.btn(".btn",{"class":T.$v("class")},T.$v("label"))));

...which is actually a little bit _shorter_ than the HTML it generates!


> See the examples folder for more examples.


## Benefits

  * Extremely lightweight: the entire library is only 4KB!

  * You can indent your code for HTML-like readability, and all that extra
  whitespace will disappear once minified

  * Faster to write than HTML: no closing tags, convenient syntax for
  `class` and `id` attributes


## Performance

Coming soon...
