// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This part of checked_mirrors contains definitions for controlling the
/// checked_mirrors library. In particular, to initialize it and to listen
/// for warnings.
library checked_mirrors.control;

import 'dart:mirrors';

import 'package:logging/logging.dart';

import 'src/checker.dart';
import 'src/utils.dart';

export 'src/checker.dart' show onWarning, MirrorsUsedWarning,
    MirrorsUsedWarningKind;

/// Initializes checked_mirrors.
///
/// **Note**: this function must be invoked before any uses of the mirror system
/// in the program. If possible, it should be the first thing in `main`.
///
/// This loads up any declarations of MirrorsUsed and sets up the necessary
/// checks on each mirror access. 
///
/// By default, warnings are available through the [onWarning] stream.
/// Alternatively, setting [log] to true will automatically log a formatted
/// warning message in a logger named `checked_mirrors`. The first logged
/// message will include a longer explanation of where these warnings come from,
/// and, if provided, any additional [hints] for how to fix things up.  By
/// default there are no hints, but frameworks that have special annotations
/// that indirectly declare a [MirrorUsed] constaint might want to include some
/// extra hints here.
///
/// If [throwOnwarning] is true, the system will throw as soon a soon as an
/// it detects a warning.
void initialize({bool throwOnWarning, bool log, String hints}) {
  checker.init(throwOnWarning: throwOnWarning);
  if (log) {
    var logger = new Logger('checked_mirrors');
    bool first = true;
    hints = hints == null ? '' : hints;
    onWarning.listen((warning) {
      if (first) {
        first = false;
        logger.warning('$FIRST_ERROR_MESSAGE$hints');
      }
      var message;
      if (warning.kind == MirrorsUsedWarningKind.UNDECLARED_SYMBOL) {
        var name = MirrorSystem.getName(warning.symbol);
        message = 'Symbol "$name" was used, but it is missing a '
            '@MirrorsUsed annotation.';
      } else {
        var declaration = getDeclarationOf(warning.object);
        var exp = declaration != null ?
            MirrorSystem.getName(declaration.simpleName) : warning.object;
        var name = MirrorSystem.getName(warning.symbol);
        message = 'Tried to access "$exp.$name" via mirrors, '
            'but it is missing a @MirrorsUsed annotation.';
      }
      logger.warning(message);
    });
  }
}

/// Default error message shown when the first error is found. This constant is
/// visible mainly for testing purposes.
const String FIRST_ERROR_MESSAGE =
    'Parts of your program uses mirrors to access objects. Some '
    'of these mirror accesses were not declared with @MirrorsUsed annotations. '
    'This could lead to unexpected behavior when deploying your app '
    'with dart2js. Below, you will find additional warnings where we '
    'detected that the @MirrorsUsed annotation is missing.';
