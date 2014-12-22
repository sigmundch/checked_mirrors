// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Replaces uses of "package:checked_mirrors/checked_mirrors.dart" with
 * "dart:mirrors" that contain the MirrorUsed annotation.
 */
library checked_mirrors.transformer;

import 'dart:async';

import 'package:barback/barback.dart';

/**
 * A [Transformer] that replaces observables based on dirty-checking with an
 * implementation based on change notifications.
 *
 * The transformation adds hooks for field setters and notifies the observation
 * system of the change.
 */
class CheckedMirrorsTransformer extends Transformer {

  final List<String> _files;
  CheckedMirrorsTransformer() : _files = null;
  CheckedMirrorsTransformer.asPlugin(BarbackSettings settings)
      : _files = _readFiles(settings.configuration['files']);

  static List<String> _readFiles(value) {
    if (value == null) return null;
    var files = [];
    bool error;
    if (value is List) {
      files = value;
      error = value.any((e) => e is! String);
    } else if (value is String) {
      files = [value];
      error = false;
    } else {
      error = true;
    }
    if (error) print('Invalid value for "files" in the observe transformer.');
    return files;
  }

  Future<bool> isPrimary(Asset input) {
    if (input.id.extension != '.dart' ||
        (_files != null && !_files.contains(input.id.path))) {
      return new Future.value(false);
    }
    return input.readAsString().then(
        (c) => c.contains("package:checked_mirrors.dart/checked_mirrors.dart"));
  }

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((content) {
      var id = transform.primaryInput.id;
      // TODO(sigmund): do a real transformer that only replaces imports, not
      // all occurrences of this string.
      // -----
      // TODO(sigmund): move the @MirrorUsed from the field to the import
      // need to do this before this CL is ready.
      // ----
      transform.addOutput(new Asset.fromString(id, content.replaceAll(
            "package:checked_mirrors.dart/checked_mirrors.dart",
            "dart:mirrors")));
    });
  }
}
