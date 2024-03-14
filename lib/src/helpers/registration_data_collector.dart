import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

import '../models/annotation_attributes.dart';
import '../models/import_path.dart';
import '../models/registrations.dart';
import 'annotation_processor.dart';
import 'class_hierarchy_explorer.dart';
import 'import_path_resolver.dart';

class RegistrationDataCollector {
  static RegistrationData? collectFromClassElement(
      ClassElement element, BuildStep buildStep) {
    for (var annotation in element.metadata) {
      var annotationReader = ConstantReader(annotation.computeConstantValue());

      if (AnnotationProcessor.isRegisterInstance(annotationReader)) {
        return _collectInstanceData(element, buildStep);
      } else if (AnnotationProcessor.isRegisterFactory(annotationReader)) {
        return _collectFactoryData(element, buildStep);
      } else if (AnnotationProcessor.isRegisterLazy(annotationReader)) {
        return _collectLazyData(element, buildStep);
      }
    }
    return null;
  }

  static InstanceData _collectInstanceData(
      ClassElement element, BuildStep buildStep) {
    final Set<SuperTypeData> superClasses =
        ClassHierarchyExplorer.explore(element, buildStep);
    final List<String> constructorParams = _getConstructorParams(element);
    final AnnotationAttributes attributes = _getAnnotationAttributes(element);
    final ImportPath importPath =
        ImportPathResolver.determineImportPath(element, buildStep);

    return InstanceData(
      importPath: importPath,
      className: element.name,
      dependencies: constructorParams,
      interfaces: superClasses.toList(),
      name: attributes.name,
      key: attributes.key,
      environment: attributes.environment,
    );
  }

  static FactoryData _collectFactoryData(
      ClassElement element, BuildStep buildStep) {
    final Set<SuperTypeData> superClasses =
        ClassHierarchyExplorer.explore(element, buildStep);
    List<String> constructorParams = _getConstructorParams(element);
    String? factoryMethodName = _findAnnotatedFactoryMethodName(element);
    Map<String, String> namedArgs = {};
    final AnnotationAttributes attributes = _getAnnotationAttributes(element);
    final ImportPath importPath =
        ImportPathResolver.determineImportPath(element, buildStep);

    if (factoryMethodName != null) {
      // Factory method is present, collect named arguments from it
      MethodElement factoryMethod = element.getMethod(factoryMethodName)!;
      namedArgs = _getNamedParameters(factoryMethod);
    } else {
      // No factory method, collect named arguments from the constructor
      ConstructorElement? constructor =
          element.unnamedConstructor ?? element.constructors.first;
      namedArgs = _getNamedParametersFromConstructor(constructor);
    }

    return FactoryData(
      interfaces: superClasses.toList(),
      importPath: importPath,
      className: element.name,
      dependencies: constructorParams,
      factoryMethod: factoryMethodName,
      namedArgs: namedArgs,
      name: attributes.name,
      key: attributes.key,
      environment: attributes.environment,
    );
  }

  static LazyData _collectLazyData(ClassElement element, BuildStep buildStep) {
    final Set<SuperTypeData> superClasses =
        ClassHierarchyExplorer.explore(element, buildStep);
    final AnnotationAttributes attributes = _getAnnotationAttributes(element);
    final List<String> constructorParams = _getConstructorParams(element);
    final ImportPath importPath =
        ImportPathResolver.determineImportPath(element, buildStep);

    final returnType = element.name;

    return LazyData(
      importPath: importPath,
      className: element.name,
      returnType: returnType,
      dependencies: constructorParams,
      interfaces: superClasses.toList(),
      name: attributes.name,
      key: attributes.key,
      environment: attributes.environment,
    );
  }

  static AnnotationAttributes _getAnnotationAttributes(ClassElement element) {
    for (var annotation in element.metadata) {
      var annotationReader = ConstantReader(annotation.computeConstantValue());
      if (AnnotationProcessor.isRegisterInstance(annotationReader) ||
          AnnotationProcessor.isRegisterFactory(annotationReader)) {
        final String? name = annotationReader.read('_name').isNull
            ? null
            : annotationReader.read('_name').stringValue;
        final dynamic key = annotationReader.read('_key').isNull
            ? null
            : annotationReader.read('_key').literalValue;
        final String? environment = annotationReader.read('_environment').isNull
            ? null
            : annotationReader.read('_environment').stringValue;

        return AnnotationAttributes(
            name: name, key: key, environment: environment);
      }
    }
    return AnnotationAttributes();
  }

  static List<String> _getConstructorParams(ClassElement element) {
    // Attempt to find the default constructor; if not found, use the first constructor as a fallback
    final ConstructorElement constructor =
        element.unnamedConstructor ?? element.constructors.first;

    // Use null-aware operators to handle the case where the constructor might be null
    return constructor.parameters
        .where(
            (param) => !param.isNamed) // Optionally, exclude named parameters
        .map((param) => param.type.getDisplayString(withNullability: false))
        .toList(); // Provide an empty list as a fallback if 'constructor' is null
  }

  static String? _findAnnotatedFactoryMethodName(ClassElement element) {
    for (var method in element.methods) {
      // Check if the method is annotated with @RegisterFactoryMethod
      var annotation = TypeChecker.fromRuntime(RegisterFactoryMethod)
          .firstAnnotationOfExact(method);
      if (annotation != null) {
        return method.name;
      }
    }
    // Return null if no annotated factory method is found
    return null;
  }

  static Map<String, String> _getNamedParameters(ExecutableElement method) {
    return Map.fromEntries(method.parameters
        .where((param) => param.isNamed)
        .map((param) => MapEntry(
            param.name, param.type.getDisplayString(withNullability: false))));
  }

  static Map<String, String> _getNamedParametersFromConstructor(
      ConstructorElement constructor) {
    return Map.fromEntries(constructor.parameters
        .where((param) => param.isNamed)
        .map((param) => MapEntry(
            param.name, param.type.getDisplayString(withNullability: false))));
  }
}
