_ = require('../vendor/lodash-2.4.1.compat.js')
T = require('../src/main')(_)

console.log "\nSimple:"

template =
  T.d '#main.container',
    T.p style: ['margin:10px 0', 'font-weight:bold'],
      T.button '.btn.btn-lg', {class: T.$v('class')}, T.$v('label')


console.log template(class: 'success', label: 'Click Here')


console.log "\nWith $map:"

template = T.$c 'd button p', (d, button, p) ->
  d '#main.container',
    p style: 'margin 10px 0',
      T.$m T.$v('labels'), (lbl) ->
        button '.btn.btn-lg', type: 'button',
          class: 'btn-'+lbl, lbl


console.log template labels: ['default', 'primary', 'success']


console.log "\n"
