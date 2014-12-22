import 'dart:mirrors' as m;
import 'package:checked_mirrors/checked_mirrors.dart';
import 'package:checked_mirrors/control.dart';

import 'package:logging/logging.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/compact_vm_config.dart';

@MirrorsUsed(symbols: 'y', targets: const [B], metaTargets: const[Reflected])
const checked_mirrors_workaround_for_issue_10360 = 0;

class Reflected { const Reflected(); }
const reflected = const Reflected();

class A {
  int x = 1;
  int y = 2; // declared symbol 'y', but target is not declared either
}

class B {
  int x = 3; // covered by class B
}

@Reflected() // all symbols in this class are declared
class C {
  int x = 4;
  int z = 5;
}

class D {
  @reflected int x = 6;
  int z = 7; // not declared
}

var a = new A();
var b = new B();
var c = new C();
var d = new D();

main() {
  useCompactVMConfiguration();
  initialize(throwOnWarning: true);

  group('get name,', () {
    test('default mirrors', () {
      expect(m.MirrorSystem.getName(#x), 'x');
      expect(m.MirrorSystem.getSymbol('x'), #x);
      expect(m.MirrorSystem.getName(#y), 'y');
      expect(m.MirrorSystem.getSymbol('y'), #y);
    });

    test('symbol is declared', () {
      expect(MirrorSystem.getName(#y), 'y');
      expect(MirrorSystem.getSymbol('y'), #y);
    });

    test('symbol is not declared', () {
      expect(() => MirrorSystem.getName(#x), throws);
      expect(() => MirrorSystem.getSymbol('x'), throws);
    });
  });

  group('get field,', () {
    test('default mirrors', () {
      expect(m.reflect(a).getField(#y).reflectee, 2);
      expect(m.reflect(b).getField(#x).reflectee, 3);

      expect(m.reflect(c).getField(#x).reflectee, 4);
      expect(m.reflect(c).getField(#z).reflectee, 5);

      expect(m.reflect(d).getField(#x).reflectee, 6);
      expect(m.reflect(d).getField(#z).reflectee, 7);
    });

    test('symbol is not declared', () {
      expect(() => reflect(a).getField(#x), throws);
    });

    test('even if symbol is declared', () {
      expect(() => reflect(a).getField(#y), throws);
    });

    test('target is declared', () {
      expect(reflect(b).getField(#x).reflectee, 3);
    });

    test('meta target is declared on class', () {
      expect(reflect(c).getField(#x).reflectee, 4);
      expect(reflect(c).getField(#z).reflectee, 5);
    });

    test('meta target is declared on field', () {
      expect(reflect(d).getField(#x).reflectee, 6);
      expect(() => reflect(d).getField(#z), throws);
    });
  });

  group('set field,', () {
    test('default mirrors', () {
      m.reflect(a).setField(#x, 101);
      m.reflect(a).setField(#y, 102);
      m.reflect(b).setField(#x, 103);
      m.reflect(c).setField(#x, 104);
      m.reflect(c).setField(#z, 105);
      m.reflect(d).setField(#x, 106);
      m.reflect(d).setField(#z, 107);

      expect(a.x, 101);
      expect(a.y, 102);
      expect(b.x, 103);
      expect(c.x, 104);
      expect(c.z, 105);
      expect(d.x, 106);
      expect(d.z, 107);
    });

    test('symbol not declared', () {
      expect(() => reflect(a).setField(#x, 201), throws);
    });

    test('even if symbol is declared', () {
      expect(() => reflect(a).setField(#x, 202), throws);
    });

    test('target is declared', () {
      reflect(b).setField(#x, 203);
      expect(b.x, 203);
    });

    test('meta target is declared on class', () {
      reflect(c).setField(#x, 204);
      reflect(c).setField(#z, 205);
      expect(c.x, 204);
      expect(c.z, 205);
    });

    test('meta target is declared on field', () {
      reflect(d).setField(#x, 206);
      expect(() => reflect(d).setField(#z, 207), throws);
      expect(d.x, 206);
    });
  });
}
