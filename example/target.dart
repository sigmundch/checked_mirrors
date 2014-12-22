// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Example illustrating how to use checked_mirrors, and how it works when you
/// declare a target with [MirrorsUsed].
library checked_mirrors.example.target;

import 'package:checked_mirrors/checked_mirrors.dart';
import 'package:checked_mirrors/control.dart' as control;
import 'package:logging/logging.dart';

// Typically this annotation goes in an import to 'dart:mirrors', we would like
// to put it in the import of checked_mirrors, but we moved it here until
// dartbug.com/10360 is fixed.
@MirrorsUsed(targets: const [A])
const checked_mirrors_workaround_for_issue_10360 = 0;

class A { // this class is declared in @MirrorsUsed, so using 'x' is OK.
  int x = 1;
}

class B { // this class is not declared, so reading 'x' will issue warnings.
  int x = 1;
}

var a = new A();
var b = new B();

main() {
  // This loads up the rules declared with @MirrorsUsed.
  control.initialize(log: true);

  // Print the warnings to the console.
  Logger.root.onRecord.listen((r) => print(r));

  var ax = reflect(a).getField(#x).reflectee;
  var bx = reflect(b).getField(#x).reflectee;

  reflect(a).setField(#x, ax + 1);
  reflect(b).setField(#x, bx + 2);
}
