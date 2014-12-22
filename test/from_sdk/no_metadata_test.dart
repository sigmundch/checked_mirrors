// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:checked_mirrors/checked_mirrors.dart';

import 'stringify.dart';

class Foo {
}

main() {
  expect('[]', reflectClass(Foo).metadata);
}
