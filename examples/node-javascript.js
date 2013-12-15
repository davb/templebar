_ = require('../vendor/lodash-2.4.1.compat.js')
T = require('../templebar-0.1.1.min')(_)

var template = T.$c('d button p', function(d, button, p) {
  return d('.container',
    p({style: 'margin:10px 0'},
      T.$v('labels'),
      T.$m(T.$v('labels'), function(lbl) {
        return button('.btn.btn-lg',
                {type: 'button', class: 'btn-'+lbl}, lbl)
      })))
});

console.log(template({labels: ['default', 'primary', 'success']}));