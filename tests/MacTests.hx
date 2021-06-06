// Copyright 26-Mar-2019 ºDeme
// GNU General Public License - V3 <http://www.gnu.org/licenses/>

import dm.Test;
import dm.Js;
import dm.Opt;
// Allows to use added functions.
using MacTst;

class MacTests {
  public static function run() {
    final t = new Test("Mac");

    final t1 = new MacTst(
      [[true]], 32, None, ["a" => ["aa" => 1, "bb" => 2]], [A, B, A], []
    );
    t.eq(t1.v1, 32);

    final t2 = new MacTst([], 12, Some(3.5), [], [B, B, B], [t1]);
    t.eq(t2.v1, 12);
    final t2Js = t2.toJs();
    final t3 = MacTst.fromJs(t2Js);

    t.eq(t3.toJs().to(), t2Js.to());

    t.eq(JsTstType.to(B).to(), "\"B\"");
    t.eq(JsTstType.from(Js.ws("B")), B);

    final t3 = t2.setV1(100);
    t.eq(t3.v1, 100);

    // Added fields.
    t.eq(t2.sum(3), 15);
    t.eq(MacTst.sum2(3, 2), 5);

    t.log();
  }

}
