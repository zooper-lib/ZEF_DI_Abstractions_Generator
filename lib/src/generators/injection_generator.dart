import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker _registrationTypeChecker =
    TypeChecker.fromRuntime(Registration);

class InjectionGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    print('Starting generator');

    final StringBuffer buffer = StringBuffer();

    // Get all annotated classes
    final classes = await _getAllAnnotatedClasses(library, buildStep);

    // Generate the code
    for (final className in classes) {
      // Example of generating a factory method for each class
      buffer.writeln("class ${className}Factory {");
      buffer.writeln("  static $className create() {");
      buffer.writeln("    return $className();");
      buffer.writeln("  }");
      buffer.writeln("}");
    }

    return buffer.toString();
  }

  Future<List<String>> _getAllAnnotatedClasses(
      LibraryReader library, BuildStep buildStep) async {
    final classes = <String>[];

    for (final c in library
        .annotatedWith(_registrationTypeChecker)
        .map((e) => e.element as ClassElement)) {
      classes.add(c.name);
    }

    return classes;
  }

  bool _hasInjectable(ClassElement element) {
    return _registrationTypeChecker.hasAnnotationOf(element);
  }
}
