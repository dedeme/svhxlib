// Copyright 26-Mar-2019 ºDeme
// GNU General Public License - V3 <http://www.gnu.org/licenses/>

import dm.Test;
import dm.Mac;
import dm.Js;
import dm.Opt;

enum TstType {A; B;}

@:build(dm.Mac.enumeration())
class JsTstType {}


@:build(dm.Mac.record([
  "v0: Array<Array<Bool>>",
  "v1: Int",
  "v2: Option<Float>",
  "v3: Map<String, Map<String, Int>>",
  "v4: Array<TstType>",
  "v5: Array<MacTst>"
], true))
class MacTst {}

// It must be imported by 'using'
class MacTests0 {
  // Adds a instance function.
  public static function sum(cl: MacTst, n: Int): Int {
    return cl.v1 + n;
  }

  // Adds a static function.
  public static function sum2(cl: Class<MacTst>, n1: Int, n2: Int): Int {
    return n1 + n2;
  }
}
