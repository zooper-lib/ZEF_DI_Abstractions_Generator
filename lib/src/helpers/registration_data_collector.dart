import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';
import 'package:zef_di_abstractions_generator/src/helpers/constructor_processor.dart';

import '../models/annotation_attributes.dart';
import '../models/import_path.dart';
import '../models/registrations.dart';
import 'annotation_processor.dart';
import 'class_hierarchy_explorer.dart';
import 'import_path_resolver.dart';
import 'method_processor.dart';

class RegistrationDataCollector {
  static RegistrationData? collect(ClassElement element, BuildStep buildStep) {
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

    // As the class can be annotated with any other annotation, which is not a ZEF annotation, we return null and dont throw an error
    return null;
  }

  static InstanceData _collectInstanceData(
    ClassElement element,
    BuildStep buildStep,
  ) {
    // Get the super classes of the class
    final Set<SuperTypeData> superClasses =
        ClassHierarchyExplorer.explore(element, buildStep);

    // Get the constructor parameters of the class
    final List<String> constructorParams =
        ConstructorProcessor.getConstructorParams(element);

    // Get the annotation attributes
    final AnnotationAttributes attributes =
        AnnotationProcessor.getAnnotationAttributes(element);

    // Get the import path of the class
    final ImportPath importPath =
        ImportPathResolver.determineImportPathForClass(element, buildStep);

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
    // Get the super classes of the class
    final Set<SuperTypeData> superClasses =
        ClassHierarchyExplorer.explore(element, buildStep);

    // Get the constructor parameters of the class
    final List<String> constructorParams =
        ConstructorProcessor.getConstructorParams(element);

    // Get the annotation attributes
    final AnnotationAttributes attributes =
        AnnotationProcessor.getAnnotationAttributes(element);

    // Get the import path of the class
    final ImportPath importPath =
        ImportPathResolver.determineImportPathForClass(element, buildStep);

    // Get the factory method name, if any
    String? factoryMethodName = _findAnnotatedFactoryMethodName(element);
    Map<String, String> namedArgs = {};

    if (factoryMethodName != null) {
      // Factory method is present, collect named arguments from it
      MethodElement factoryMethod = element.getMethod(factoryMethodName)!;
      namedArgs = MethodProcessor.getNamedParameters(factoryMethod);
    } else {
      // No factory method, collect named arguments from the constructor
      ConstructorElement? constructor =
          element.unnamedConstructor ?? element.constructors.first;
      namedArgs = ConstructorProcessor.getNamedParameters(constructor);
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
    // Get the super classes of the class
    final Set<SuperTypeData> superClasses =
        ClassHierarchyExplorer.explore(element, buildStep);

    // Get the constructor parameters of the class
    final List<String> constructorParams =
        ConstructorProcessor.getConstructorParams(element);

    // Get the annotation attributes
    final AnnotationAttributes attributes =
        AnnotationProcessor.getAnnotationAttributes(element);

    // Get the import path of the class
    final ImportPath importPath =
        ImportPathResolver.determineImportPathForClass(element, buildStep);

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
}
