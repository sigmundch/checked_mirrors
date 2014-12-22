// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An implementation of dart:mirrors that checks if everything accessed through
/// reflection has been declared via the @MirrorUsed API.
///
/// Usage:
///
///   * Import `package:checked_mirrors/checked_mirrors.dart` instead of
///     `dart:mirrors`.
///
///   * Move the @[MirrorsUsed] annotations to a top-level const symbol named
///     `checked_mirrors_workaround_for_10360`. This step is needed temporarily
///     until issue [10360](http://dartbug.com/10360) is fixed.
///
///   * Add a transformer section to your pubspec to include a phase that will
///     remove the checks from this library when you deploy your application:
///
///         transformers:
///         - checked_mirrors

library checked_mirrors;

// Except for top-level APIs, expose everything else.
export "dart:mirrors" hide currentMirrorSystem, reflect, reflectClass,
       reflectType, MirrorSystem;

import 'dart:async';
import "dart:collection" show ListMixin;
import 'dart:isolate';
import "dart:mirrors" as mirrors;
import "dart:mirrors" hide currentMirrorSystem, reflect, reflectClass,
       reflectType, MirrorSystem;

import 'src/checker.dart';

/// An expando to store existing wrappers, since some APIs are expected to
/// return the same instance (at least according to the mirror tests).
Expando _wrappers = new Expando();

/// Returns a wrapper for [original], an object from the base mirror system. We
/// internally try to store the wrapper in an expando to ensure we use the same
/// wrapper whenever it's possible.
_wrap(original) {
  if (original == null) return null;
  var value = _wrappers[original];
  if (value != null) return value;
  value = _createWrapper(original);
  _wrappers[original] = value;
  return value;
}

/// Creates a wrapper for [original] assuming one doesn't exist already. The
/// wrapper will be a corresponding object in this library, for instance
/// _ClosureMirror for ClosureMirror. This function also wraps maps and lists
/// whose values are mirror system objects.
_createWrapper(original) {
  // Note: the order below is important to guarnatee we create the most precise
  // wrapper for a given type (e.g. FunctionTypeMirror is a ClassMirror too).

  if (original is Map) return new _MapWrapper(original);
  if (original is List) return new _ListWrapper(original);
  if (original is FunctionTypeMirror) return new _FunctionTypeMirror(original);
  if (original is ClassMirror) return new _ClassMirror(original);

  if (original is ClosureMirror) return new _ClosureMirror(original);
  if (original is InstanceMirror) return new _InstanceMirror(original);
  if (original is LibraryMirror) return new _LibraryMirror(original);
  if (original is ObjectMirror) return new _ObjectMirror(original);

  if (original is ParameterMirror) return new _ParameterMirror(original);
  if (original is VariableMirror) return new _VariableMirror(original);

  if (original is TypeVariableMirror) return new _TypeVariableMirror(original);
  if (original is IsolateMirror) return new _IsolateMirror(original);
  if (original is MethodMirror) return new _MethodMirror(original);
  if (original is mirrors.MirrorSystem) return new MirrorSystem(original);
  if (original is TypedefMirror) return new _TypedefMirror(original);

  if (original is TypeMirror) return new _TypeMirror(original);
  if (original is DeclarationMirror) return new _DeclarationMirror(original);
  throw "Unknown mirror type: ${original.runtimeType}";
}

MirrorSystem _current = _wrap(mirrors.currentMirrorSystem());
MirrorSystem currentMirrorSystem() => _current;
InstanceMirror reflect(Object reflectee) => _wrap(mirrors.reflect(reflectee));
ClassMirror reflectClass(Type key) => _wrap(mirrors.reflectClass(key));
TypeMirror reflectType(Type key) => _wrap(mirrors.reflectType(key));

class _Mirror {
  dynamic _original;
  _Mirror(this._original);

  toString() => _original.toString();
}

// We use the original name for this class because it exposes static methods
// that could be used externally.
// TODO(sigmund): technically the top-level symbols exposed here could be used
// too, like #LibraryMirror. Maybe we need to override the names of all these
// symbols?
class MirrorSystem extends _Mirror with mirrors.MirrorSystem {
  MirrorSystem(original) : super(original);

  Map<Uri, LibraryMirror> get libraries => _wrap(_original.libraries);

  IsolateMirror get isolate => _wrap(_original.isolate);

  TypeMirror get dynamicType => _wrap(_original.dynamicType);

  TypeMirror get voidType => _wrap(_original.voidType);

  static String getName(Symbol symbol) {
    checker.useSymbol(symbol);
    return mirrors.MirrorSystem.getName(symbol);
  }

  static Symbol getSymbol(String name, [LibraryMirror library]) {
    if (library == null) {
      var symbol = mirrors.MirrorSystem.getSymbol(name);
      checker.useSymbol(symbol);
      return symbol;
    }
    if (library is! _LibraryMirror) {
      throw new ArgumentError("$library is not a LibraryMirror");
    }
    _LibraryMirror lib = library; // type-check
    var symbol = mirrors.MirrorSystem.getSymbol(name, lib._original);
    checker.useSymbol(symbol);
    return symbol;
  }
}

class _IsolateMirror extends _Mirror implements mirrors.IsolateMirror {
  _IsolateMirror(original) : super(original);

  String get debugName => _original.debugName;
  bool get isCurrent => _original.isCurrent;
  LibraryMirror get rootLibrary => _wrap(_original.rootLibrary);
  bool operator == (other) {
    if (other == null || other is! _IsolateMirror) return false;
    return _original == other._original;
  }
  int get hashCode => _original.hashCode;
}

abstract class _DeclarationMirrorMixin implements mirrors.DeclarationMirror {
  get _original;
  Symbol get simpleName => _original.simpleName;
  Symbol get qualifiedName => _original.qualifiedName;
  DeclarationMirror get owner => _wrap(_original.owner);
  bool get isPrivate => _original.isPrivate;
  bool get isTopLevel => _original.isTopLevel;
  SourceLocation get location => _original.location;
  List<InstanceMirror> get metadata => _wrap(_original.metadata);
}

class _DeclarationMirror extends _Mirror with _DeclarationMirrorMixin
    implements mirrors.DeclarationMirror {
  _DeclarationMirror(original) : super(original);
  get _original => super._original; // to get rid of static warnings

}

abstract class _ObjectMirrorMixin implements mirrors.ObjectMirror {
  get _original;

  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol,dynamic> namedArguments]) =>
      _wrap(_original.invoke(memberName, positionalArguments, namedArguments));

  InstanceMirror getField(Symbol fieldName) {
    checker.access(_original, fieldName);
    return _wrap(_original.getField(fieldName));
  }

  InstanceMirror setField(Symbol fieldName, Object value) {
    checker.access(_original, fieldName);
    return _wrap(_original.setField(fieldName, value));
  }
}

class _ObjectMirror extends _Mirror with _ObjectMirrorMixin
    implements mirrors.ObjectMirror {
  _ObjectMirror(original) : super(original);
  get _original => super._original; // to get rid of static warnings
}

class _InstanceMirror extends _ObjectMirror implements mirrors.InstanceMirror {
  _InstanceMirror(original) : super(original);

  ClassMirror get type => _wrap(_original.type);
  bool get hasReflectee => _original.hasReflectee;
  get reflectee => _original.reflectee;
  bool operator == (other) {
    if (other == null || other is! _InstanceMirror) return false;
    return _original == other._original;
  }
  int get hashCode => _original.hashCode;

  delegate(Invocation invocation) => _original.delegate(invocation);
  Function operator [](Symbol name) {
    print('warning: this cannot be debugged: InstanceMirror.operator[]');
    // TODO(sigmund): we'd like to wrap the result inside the function, but we
    // don't have a way to dynamically take arguments.
    return _original[name];
  }
}

class _ClosureMirror extends _InstanceMirror implements mirrors.ClosureMirror {
  _ClosureMirror(original) : super(original);

  MethodMirror get function => _wrap(_original.function);
  InstanceMirror apply(List positionalArguments,
                       [Map<Symbol, dynamic> namedArguments]) =>
      _wrap(_original.apply(positionalArguments, namedArguments));
  InstanceMirror findInContext(Symbol name, {ifAbsent: null}) =>
      _wrap(_original.findInContext(name, ifAbsent: ifAbsent));
}

class _LibraryMirror extends _DeclarationMirror with _ObjectMirrorMixin
    implements mirrors.LibraryMirror {
  _LibraryMirror(original) : super(original);
  get _original => super._original; // to get rid of static warnings

  Uri get uri => _original.uri;
  Map<Symbol, DeclarationMirror> get declarations =>
      _wrap(_original.declarations);

  Map<Symbol, MethodMirror> get topLevelMembers =>
      _wrap(_original.topLevelMembers);

  bool operator == (other) {
    if (other == null || other is! _LibraryMirror) return false;
    return _original == other._original;
  }
  int get hashCode => _original.hashCode;

  Function operator [](Symbol name) {
    print('warning: this cannot be debugged: LibraryMirror.operator[]');
    // TODO(sigmund): we'd like to wrap the result inside the function, but we
    // don't have a way to dynamically take arguments.
    return _original[name];
  }
}

class _TypeMirror extends _DeclarationMirror implements mirrors.TypeMirror {
  _TypeMirror(original) : super(original);

  List<TypeVariableMirror> get typeVariables =>
      _wrap(_original.typeVariables);
  List<TypeMirror> get typeArguments =>
      _wrap(_original.typeArguments);
  bool get isOriginalDeclaration => _original.isOriginalDeclaration;
  TypeMirror get originalDeclaration =>
      _wrap(_original.originalDeclaration);

  bool operator == (other) {
    if (other == null || other is! _TypeMirror) return false;
    return _original == other._original;
  }
  int get hashCode => _original.hashCode;
}

class _ClassMirror extends _TypeMirror with _ObjectMirrorMixin
    implements ClassMirror {
  _ClassMirror(original) : super(original);

  bool get hasReflectedType => _original.hasReflectedType;
  Type get reflectedType => _original.reflectedType;
  ClassMirror get superclass => _wrap(_original.superclass);
  List<ClassMirror> get superinterfaces =>
      _wrap(_original.superinterfaces);

  Map<Symbol, DeclarationMirror> get declarations =>
      _wrap(_original.declarations);
  Map<Symbol, MethodMirror> get instanceMembers =>
      _wrap(_original.instanceMembers);
  Map<Symbol, MethodMirror> get staticMembers =>
      _wrap(_original.staticMembers);
  ClassMirror get mixin => _wrap(_original.mixin);
  InstanceMirror newInstance(Symbol constructorName,
                             List positionalArguments,
                             [Map<Symbol,dynamic> namedArguments]) =>
      _wrap(_original.newInstance(constructorName,
            positionalArguments, namedArguments));

  bool operator == (other) {
    if (other == null || other is! _ClassMirror) return false;
    return _original == other._original;
  }
  int get hashCode => _original.hashCode;

  Function operator [](Symbol name) {
    print('warning: this cannot be debugged: ClassMirror.operator[]');
    // TODO(sigmund): we'd like to wrap the result inside the function, but we
    // don't have a way to dynamically take arguments.
    return _original[name];
  }
}

class _FunctionTypeMirror extends _ClassMirror implements FunctionTypeMirror {
  _FunctionTypeMirror(original) : super(original);
  get _original => super._original; // to get rid of static warnings

  TypeMirror get returnType => _wrap(_original.returnType);
  List<ParameterMirror> get parameters =>
      _wrap(_original.parameters);
  MethodMirror get callMethod => _wrap(_original.callMethod);
}

class _TypeVariableMirror extends _TypeMirror implements TypeVariableMirror {
  _TypeVariableMirror(original) : super(original);

  TypeMirror get upperBound => _wrap(_original.upperBound);
  bool get isStatic => _original.isStatic;
  bool operator == (other) {
    if (other == null || other is! _TypeVariableMirror) return false;
    return _original == other._original;
  }
  int get hashCode => _original.hashCode;
}

class _TypedefMirror extends _TypeMirror implements TypedefMirror {
  _TypedefMirror(original) : super(original);

  FunctionTypeMirror get referent => _wrap(_original.referent);
}

class _MethodMirror extends _DeclarationMirror implements MethodMirror {
  _MethodMirror(original) : super(original);

  TypeMirror get returnType => _wrap(_original.returnType);
  String get source => _original.source;
  List<ParameterMirror> get parameters =>
      _wrap(_original.parameters);
  bool get isStatic => _original.isStatic;
  bool get isAbstract => _original.isAbstract;
  bool get isSynthetic => _original.isSynthetic;
  bool get isRegularMethod => _original.isRegularMethod;
  bool get isOperator => _original.isOperator;
  bool get isGetter => _original.isGetter;
  bool get isSetter => _original.isSetter;
  bool get isConstructor => _original.isConstructor;
  Symbol get constructorName => _original.constructorName;
  bool get isConstConstructor => _original.isConstConstructor;
  bool get isGenerativeConstructor => _original.isGenerativeConstructor;
  bool get isRedirectingConstructor => _original.isRedirectingConstructor;
  bool get isFactoryConstructor => _original.isFactoryConstructor;
  bool operator == (other) {
    if (other == null || other is! _MethodMirror) return false;
    return _original == other._original;
  }
  int get hashCode => _original.hashCode;
}

class _VariableMirror extends _DeclarationMirror implements VariableMirror {
  _VariableMirror(original) : super(original);
  TypeMirror get type => _wrap(_original.type);
  bool get isStatic => _original.isStatic;
  bool get isFinal => _original.isFinal;
  bool get isConst => _original.isConst;
  bool operator == (other) {
    if (other == null || other is! _VariableMirror) return false;
    return _original == other._original;
  }
  int get hashCode => _original.hashCode;
}

class _ParameterMirror extends _VariableMirror implements ParameterMirror {
  _ParameterMirror(original) : super(original);
  TypeMirror get type => _wrap(_original.type);
  bool get isOptional => _original.isOptional;
  bool get isNamed => _original.isNamed;
  bool get hasDefaultValue => _original.hasDefaultValue;
  InstanceMirror get defaultValue => _original.defaultValue;
}

/// Wraps a map that contains mirror values
class _MapWrapper<K, V extends _Mirror> implements Map<K, V> {
  Map<K, V> _original;
  _MapWrapper(Map<K, V> original) : _original = original;

  V operator [](Object key) => _wrap(_original[key]);

  void operator []=(K key, V value) {
    _original[key] = value._original;
  }

  void addAll(Map<K, V> other) {
    other.forEach((key, value) { _original[key] = value; });
  }

  bool containsValue(Object value) =>
      _original.containsValue(value != null && (value as dynamic)._original);

  V putIfAbsent(K key, V ifAbsent()) =>
      _original.putIfAbsent(key, () => ifAbsent()._original);

  // Every other method is just delegated to the original

  Iterable<V> get values => _original.values.map(_wrap);

  void clear() => _original.clear();

  bool containsKey(Object key) => _original.containsKey(key);

  void forEach(void f(K key, V value)) {
    _original.forEach(f);
  }

  bool get isEmpty => _original.isEmpty;

  bool get isNotEmpty => _original.isNotEmpty;

  Iterable<K> get keys => _original.keys;

  int get length => _original.length;

  V remove(Object key) => _original.remove(key);
}

/// Wraps a list of mirror values
class _ListWrapper<E extends _Mirror> extends Object with ListMixin<E> {
  List _original;

  _ListWrapper(this._original);

  E operator [](int index) => _wrap(_original[index]);

  void operator []=(int index, E value) {
    _original[index] = value._original;
  }

  int get length => _original.length;

  void set length(int newLength) {
    _original.length = newLength;
  }
}
