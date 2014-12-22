// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Example illustrating how to use checked_mirrors, and how it works when you
/// declare a symbol with [MirrorsUsed].
library checked_mirrors.example.symbol;

import 'package:checked_mirrors/checked_mirrors.dart';
import 'package:checked_mirrors/control.dart' as control;
import 'package:logging/logging.dart';

// Typically this annotation goes in an import to 'dart:mirrors', we would like
// to put it in the import of checked_mirrors, but we moved it here until
// dartbug.com/10360 is fixed.
@MirrorsUsed(symbols: 'x')
const checked_mirrors_workaround_for_issue_10360 = 0;

var a = new A();

main() {
  // This loads up the rules declared with @MirrorsUsed.
  control.initialize(log: true);

  // Print the warnings to the console.
  Logger.root.onRecord.listen((r) => print(r));

  // These are OK:
  MirrorSystem.getName(#x);
  MirrorSystem.getSymbol('x');

  // These will issue a warning:
  MirrorSystem.getName(#y);
  MirrorSystem.getSymbol('y');
}
