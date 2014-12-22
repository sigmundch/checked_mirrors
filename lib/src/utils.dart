// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Holds some common functions that manipulate mirror objects.
library checked_mirrors.src.utils;

import 'dart:mirrors';

/// Helper to retrieve the library uri where [object] is defined.
Uri getLibraryUriOf(Mirror object) {
  var declaration = getDeclarationOf(object);
  if (declaration == null) return null;
  if (declaration is LibraryMirror) return declaration.uri;
  return getLibraryUriOf(declaration.owner);
}

/// Helper to retrieve the declaration of [object].
DeclarationMirror getDeclarationOf(Mirror object) {
  if (object is DeclarationMirror) return object;
  if (object is InstanceMirror) return object.type;
  return null;
}
