#!/bin/bash
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This script generates all tests under pkg/checked_mirrors/test/from_sdk/ by
# coping the tests from tests/lib/mirrors/ and replacing the imports to use this
# package instead.
# 
# The pkg.status file contains the same status exclusions as dart:mirrors for
# the vm and dartium. Tests are skipped in dart2js as this package is inteded to
# be used only during development.
#
# TODO(sigmund): can we do this without copying?
set -e

echo "cp tests/lib/mirrors/* pkg/checked_mirrors/test/from_sdk"
rm pkg/checked_mirrors/test/from_sdk/*
cp tests/lib/mirrors/* pkg/checked_mirrors/test/from_sdk

files=`find pkg/checked_mirrors/test/from_sdk/ -name "*.dart"`

echo "replace 'dart:mirrors' with 'package:checked_mirrors/checked_mirrors.dart'"
sed -i "s/import 'dart:mirrors/import 'package:checked_mirrors\/checked_mirrors.dart/" $files

# some tests use unittest or a "light" unittest and they use a relative path to
# include it.
# TODO(sigmund): find out if that should be fixed directly in the tests.
echo "replace references to unittest"
sed -i "s/import '..\/..\/..\/pkg\/unittest\/lib/import 'package:unittest/" $files
sed -i "s/import '..\/..\/light_unittest.dart/import 'package:unittest\/unittest.dart/" $files
