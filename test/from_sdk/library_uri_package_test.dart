// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test library uri for a library read as a package .

library MirrorsTest;

import 'package:checked_mirrors/checked_mirrors.dart';
import 'package:args/args.dart';
import 'package:unittest/unittest.dart';

testLibraryUri(var value, Uri expectedUri) {
  var valueMirror = reflect(value);
  ClassMirror valueClass = valueMirror.type;
  LibraryMirror valueLibrary = valueClass.owner;
  expect(valueLibrary.uri, equals(expectedUri));
}

main() {
  var mirrors = currentMirrorSystem();
  test("Test package library uri", () {
    testLibraryUri(new ArgParser(), Uri.parse('package:args/args.dart'));
  });
}
