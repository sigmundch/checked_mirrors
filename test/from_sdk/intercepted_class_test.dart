// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that classes handled specially by dart2js can be reflected on.

library test.intercepted_class_test;

import 'package:checked_mirrors/checked_mirrors.dart';

import 'stringify.dart' show stringify, expect;

checkClassMirror(ClassMirror cls, String name) {
  expect('s($name)', cls.simpleName);
  var variables = new Map();
  cls.declarations.forEach((Symbol key, DeclarationMirror value) {
    if (value is VariableMirror && !value.isStatic && !value.isPrivate) {
      variables[key] = value;
    }
  });
  expect('{}', variables);
}

main() {
  checkClassMirror(reflectClass(String), 'String');
  checkClassMirror(reflectClass(int), 'int');
  checkClassMirror(reflectClass(double), 'double');
  checkClassMirror(reflectClass(num), 'num');
  checkClassMirror(reflectClass(bool), 'bool');
  checkClassMirror(reflectClass(List), 'List');
}
