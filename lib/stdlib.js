// Generated by CoffeeScript 1.9.3
(function() {
  var Decimal, PI, lib, stdlib;

  lib = require('./lib.js');

  Decimal = require('./decimal.js');

  PI = '3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113499999983729780499510597317328160963185950244594553469083026425223082533446850352619311881710100031378387528865875332083814206171776691473035982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989380952572010654858632789';

  stdlib = {
    description: 'The standard library',
    variables: {
      'MAX_DECIMAL_PRECISION': new lib.Value('number', '1e3'),
      'MAX_EXPONENT_VALUE': new lib.Value('number', '9e15'),
      'PI': new lib.Value('number', PI)
    },
    functions: {

      /* INPUT / OUTPUT */
      'print': {
        params: ['msg'],
        block: function(scope) {
          var i, j, msg, ref, res;
          msg = scope.get_var('msg');
          if (msg.type === 'array') {
            res = '[';
            for (i = j = 0, ref = msg.items.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
              res += msg.items[i].value + ', ';
            }
            console.log(res.replace(/, $/, '') + ']');
          } else {
            console.log(msg.value + '');
          }
          return msg;
        }
      },

      /* DATA TYPES */
      'typeof': {
        params: ['obj'],
        block: function(scope) {
          return new lib.Value('string', scope.get_var('obj').type);
        }
      },
      'not': {
        params: ['n'],
        block: function(scope) {
          if (lib.is_truthy(scope.get_var('n'))) {
            return new lib.Value('boolean', false);
          } else {
            return new lib.Value('boolean', true);
          }
        }
      },

      /* MATH FUNCTIONS */
      'random': {
        params: ['sd'],
        block: function(scope) {
          var r, sd;
          sd = scope.get_var('sd');
          r = Decimal.random(Number(sd.value));
          return new lib.Value('number', r.toString());
        }
      },
      'factorial': {
        params: ['n'],
        block: function(scope) {
          var i, inc, n, res;
          n = scope.get_var('n');
          i = new lib.Value('number', '1');
          inc = new lib.Value('number', '1');
          res = new lib.Value('number', '1');
          while (lib.binary_operation(i, n, '<=').value) {
            res = lib.binary_operation(res, i, '*');
            i = lib.binary_operation(i, inc, '+');
          }
          return res;
        }
      },
      'sqrt': {
        params: ['n'],
        block: function(scope) {
          var n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          return new lib.Value('number', n.value.sqrt());
        }
      },
      'log': {
        params: ['n'],
        block: function(scope) {
          var n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          return new lib.Value('number', n.value.log());
        }
      },
      'ln': {
        params: ['n'],
        block: function(scope) {
          var n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          return new lib.Value('number', n.value.ln());
        }
      },
      'abs': {
        params: ['n'],
        block: function(scope) {
          var n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          return new lib.Value('number', n.value.abs());
        }
      },
      'round': {
        params: ['n'],
        block: function(scope) {
          var n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          return new lib.Value('number', n.value.round());
        }
      },
      'floor': {
        params: ['n'],
        block: function(scope) {
          var n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          return new lib.Value('number', n.value.ceil());
        }
      },
      'ceil': {
        params: ['n'],
        block: function(scope) {
          var n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          return new lib.Value('number', n.value.floor());
        }
      },
      'sin': {
        params: ['n'],
        block: function(scope) {
          var n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          return new lib.Value('number', n.value.modulo(PI).sin());
        }
      },
      'tan': {
        params: ['n'],
        block: function(scope) {
          var n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          return new lib.Value('number', n.value.modulo(PI).tan());
        }
      },
      'cos': {
        params: ['n'],
        block: function(scope) {
          var n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          return new lib.Value('number', n.value.modulo(PI).cos());
        }
      },
      'asin': {
        params: ['n'],
        block: function(scope) {
          var n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          return new lib.Value('number', n.value.modulo(PI).asin());
        }
      },
      'atan': {
        params: ['n'],
        block: function(scope) {
          var n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          return new lib.Value('number', n.value.modulo(PI).atan());
        }
      },
      'acos': {
        params: ['n'],
        block: function(scope) {
          var n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          return new lib.Value('number', n.value.modulo(PI).acos());
        }
      },
      'toFixed': {
        params: ['n', 'd'],
        block: function(scope) {
          var d, n;
          n = lib.convert_value(scope.get_var('n'), 'number');
          d = lib.convert_value(scope.get_var('d'), 'number');
          return new lib.Value('number', n.value.toFixed(d.value));
        }
      }
    }
  };

  module.exports = stdlib;

}).call(this);
