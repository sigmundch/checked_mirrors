// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Example illustrating how to use checked_mirrors, and how it works when you
/// declare a meta-target with [MirrorsUsed].
library checked_mirrors.example.meta_target;

import 'package:checked_mirrors/checked_mirrors.dart';
import 'package:checked_mirrors/control.dart' as control;
import 'package:logging/logging.dart';

// Typically this annotation goes in an import to 'dart:mirrors', we would like
// to put it in the import of checked_mirrors, but we moved it here until
// dartbug.com/10360 is fixed.
@MirrorsUsed(metaTargets: const[Reflected])
const checked_mirrors_workaround_for_issue_10360 = 0;

class Reflected { const Reflected(); }
const reflected = const Reflected();

class A {
  int x = 1; // not annotated - reading this should give warnings.
}

@Reflected() // all symbols in this class are covered
class B {
  int y = 4;
  int z = 5;
}

class C {
  @reflected int y = 6;
  int z = 7; // not covered
}

var a = new A();
var b = new B();
var c = new C();

main() {
  // This loads up the rules declared with @MirrorsUsed.
  control.initialize(log: true);

  // Print the warnings to the console.
  Logger.root.onRecord.listen((r) => print(r));

  var x = reflect(a).getField(#x).reflectee;
  reflect(a).setField(#x, x + 1);

  var by = reflect(b).getField(#y).reflectee;
  reflect(b).setField(#y, by + 1);
  var bz = reflect(b).getField(#z).reflectee;
  reflect(b).setField(#y, bz + 1);

  var cy = reflect(c).getField(#y).reflectee;
  reflect(c).setField(#y, by + 1);
  var cz = reflect(c).getField(#z).reflectee;
  reflect(c).setField(#y, bz + 1);
}
