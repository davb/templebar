chai = require 'chai'
chai.should()


# instantiate template engine with vendored Lodash
T = require('../src/main')(require('../vendor/lodash-2.4.1.compat'))


# basic tag generation

it 'accepts an Array', ->
  T.div(['a', 1, 'b'])().should.equal '<div>a1b</div>'


it 'T.d is an alias for T.div', ->
  T.d()().should.equal T.div()()


# closing tags

it 'ignores content of self-closing tags', ->
  T.br('some-content')().should.equal '<br/>'

it 'closes content tags', ->
  T.p()().should.equal '<p></p>'


# ID and CSS classes

it 'accepts .class_name as first argument', ->
  T.p('.my-class')().should.equal '<p class="my-class"></p>'

it 'accepts #id as first argument', ->
  T.p('#my-id')().should.equal '<p id="my-id"></p>'

it 'multiple class attributes are concatenated', ->
  T.p({class: 'a'}, {class: 'b'})().should.equal '<p class="a b"></p>'
  T.p('.a', {class: 'b'})().should.equal '<p class="a b"></p>'

it 'multiple id attributes override each other', ->
  T.p({id: 'a'}, {id: 'b'})().should.equal '<p id="b"></p>'
  T.p('#a', {id: 'b'})().should.equal '<p id="b"></p>'


# style attributes

it 'accepts Array value and concatenates with ;', ->
  temp = T.p({style: ['color:#fff', 'font-size:2em']})
  temp().should.equal '<p style="color:#fff;font-size:2em"></p>'

it 'accepts Array value with variable placeholders', ->
  temp = T.p({style: [T.$v('a'), 'font-size:2em']})
  temp({a:1}).should.equal '<p style="1;font-size:2em"></p>'

it 'accepts Array value with function placeholders', ->
  temp = T.p({style: [T.$f((d) -> 'color:'+d.color), 'font-size:2em']})
  temp({color:'red'}).should.equal '<p style="color:red;font-size:2em"></p>'


# $map / $m

it 'passes each element to the callback function', ->
  temp = T.ul T.$map [1,2], (i) -> T.li('#l'+i)
  temp().should.equal '<ul><li id="l1"></li><li id="l2"></li></ul>'

it 'is aliased as $m', ->
  T.$map([1,2], (i) -> T.p(i))().should.equal T.$m([1,2], (i) -> T.p(i))()


# $var / $v

it 'defers to evaluation time', ->
  temp = T.div(T.$v('a'))
  temp({a: 1}).should.equal '<div>1</div>'
  temp({a: 2}).should.equal '<div>2</div>'

it 'supports path to nested properties', ->
  temp = T.div(T.$v('a.b'))
  temp({a: {b: 1}}).should.equal '<div>1</div>'

it 'escapes HTML', ->
  temp = T.d(T.$v('a'))
  temp({a: '"<br/>\'&'}).should.equal '<div>&quot;&lt;br&#x2F;&gt;&#39;&amp;</div>'

it 'allows to disable escaping HTML', ->
  temp = T.d(T.$v('a', 1))
  temp({a: '<br/>'}).should.equal '<div><br/></div>'


# $fun / $f

it 'defers to evaluation time', ->
  x = 0
  temp = T.div(T.$f(-> x))
  temp().should.equal '<div>0</div>'
  x = 1
  temp().should.equal '<div>1</div>'

it 'passes template data to the function', ->
  temp = T.div(T.$f((data) -> data.x + data.y))
  temp({x:1, y:2}).should.equal '<div>3</div>'


# $with / $w

it 'selects the appropriate scope', ->
  temp = T.d(T.$w('a', T.d('b')))
  temp({a: {b: 1}}).should.equal '<div><div>b</div></div>'

it 'supports nested paths', ->
  temp = T.d(T.$w('a.b', T.d('c')))
  temp({a: {b: {c: 1}}}).should.equal '<div><div>c</div></div>'


# some templates

it 'compiles correctly', ->
  temp = T.div {x: 2},
    T.div('a'),
    T.div('b'),
    T.div {y: 4},
      T.div('c')
      T.a(href: 'url', 'lol')
      T.a('.btn#main', 'lol')
      T.ul T.$map [1..3], (i) ->
        T.li 'x'+i,
          T.span 'a'
  temp().should.equal '<div x="2"><div>a</div><div>b</div><div y="4"><div>c</div><a href="url">lol</a><a id="main" class="btn">lol</a><ul><li>x1<span>a</span></li><li>x2<span>a</span></li><li>x3<span>a</span></li></ul></div></div>'