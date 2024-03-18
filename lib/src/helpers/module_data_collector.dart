import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zef_di_abstractions_generator/src/helpers/constructor_processor.dart';

import '../models/annotation_attributes.dart';
import '../models/import_path.dart';
import '../models/registrations.dart';
import 'annotation_processor.dart';
import 'class_hierarchy_explorer.dart';
import 'import_path_resolver.dart';

class ModuleDataCollector {
  static ModuleRegistration? collect(
      ClassElement element, BuildStep buildStep) {
    final List<TypeRegistration> registrations = [];
    final Set<ImportPath> importPaths = {};

    if (AnnotationProcessor.isDependencyModule(element) == false) {
      return null;
    }

    // Collect registration data and import paths from factories and lazies, aka methods
    for (var method in element.methods) {
      registrations.addAll(collectFromModuleMethod(method, buildStep));
      importPaths.addAll(_collectImportPathsFromReturnType(method, buildStep));
      importPaths.addAll(_collectImportPathsFromParameters(method, buildStep));
    }

    // Extend to collect registration data and import paths from instances, aka getters
    element.accessors.where((accessor) => accessor.isGetter).forEach((getter) {
      registrations.addAll(collectFromModuleGetter(getter, buildStep));
      importPaths.addAll(_collectImportPathsFromReturnType(getter, buildStep));
    });

    return ModuleRegistration(
      registrations: registrations,
      importPaths: importPaths,
    );
  }

  static List<TypeRegistration> collectFromModuleMethod(
    MethodElement method,
    BuildStep buildStep,
  ) {
    final List<TypeRegistration> registrations = [];

    for (var annotation in method.metadata) {
      final annotationReader =
          ConstantReader(annotation.computeConstantValue());

      //* We don't need to process Instance registrations here, as they are not allowed on methods

      if (AnnotationProcessor.isRegisterFactory(annotationReader)) {
        if (method.enclosingElement is ClassElement) {
          registrations.add(_collectFactoryData(method, buildStep,
              annotationReader, method.enclosingElement as ClassElement));
        }
      } else if (AnnotationProcessor.isRegisterLazy(annotationReader)) {
        if (method.enclosingElement is ClassElement) {
          registrations.add(_collectLazyData(method, buildStep,
              annotationReader, method.enclosingElement as ClassElement));
        }
      }
    }

    return registrations;
  }

  static List<TypeRegistration> collectFromModuleGetter(
    PropertyAccessorElement getter,
    BuildStep buildStep,
  ) {
    final List<TypeRegistration> registrations = [];

    for (var annotation in getter.metadata) {
      final annotationReader =
          ConstantReader(annotation.computeConstantValue());

      if (AnnotationProcessor.isRegisterInstance(annotationReader)) {
        if (getter.enclosingElement is ClassElement) {
          registrations.add(_collectInstanceData(getter, buildStep,
              annotationReader, getter.enclosingElement as ClassElement));
        }
      }
    }

    return registrations;
  }

  static InstanceData _collectInstanceData(
    PropertyAccessorElement getter,
    BuildStep buildStep,
    ConstantReader annotationReader,
    ClassElement classElement,
  ) {
    var returnTypeElement = getter.returnType.element;
    if (returnTypeElement is! ClassElement) {
      throw Exception("Return type of the getter is not a class.");
    }

    // Determine the import path for the getter's return type
    final ImportPath importPath =
        ImportPathResolver.determineImportPathForClass(
            returnTypeElement, buildStep);

    // Explore super types for interfaces
    final Set<SuperTypeData> superTypes =
        ClassHierarchyExplorer.explore(returnTypeElement, buildStep);

    // Get the constructor parameters of the class
    final List<String> constructorParams =
        ConstructorProcessor.getConstructorParams(returnTypeElement);

    // Get the annotation attributes
    final AnnotationAttributes attributes =
        AnnotationProcessor.getAnnotationAttributes(getter);

    return InstanceData(
      importPath: importPath,
      className: returnTypeElement.name,
      interfaces: superTypes.toList(),
      name: attributes.name,
      key: attributes.key,
      environment: attributes.environment,
      dependencies: constructorParams,
    );
  }

  static FactoryData _collectFactoryData(
    MethodElement method,
    BuildStep buildStep,
    ConstantReader annotationReader,
    ClassElement classElement,
  ) {
    var returnTypeElement = method.returnType.element;
    if (returnTypeElement is! ClassElement) {
      throw Exception("Return type of the factory method is not a class.");
    }

    // Get the super classes of the class
    final Set<SuperTypeData> superClasses =
        ClassHierarchyExplorer.explore(returnTypeElement, buildStep);

    // Get the import path of the class
    final ImportPath importPath =
        ImportPathResolver.determineImportPathForClass(
            returnTypeElement, buildStep);

    // Get the class name
    final className =
        method.returnType.getDisplayString(withNullability: false);

    // Get the constructor parameters of the class
    final List<String> constructorParams =
        ConstructorProcessor.getConstructorParams(returnTypeElement);

    // Get the constructor parameters
    //* As we dont have a factory method, we will directly use the constructor and its named parameters
    ConstructorElement? constructor =
        classElement.unnamedConstructor ?? classElement.constructors.first;
    Map<String, String> namedArgs =
        ConstructorProcessor.getNamedParameters(constructor);

    // Get the annotation attributes
    final AnnotationAttributes attributes =
        AnnotationProcessor.getAnnotationAttributes(classElement);

    return FactoryData(
      interfaces: superClasses.toList(),
      importPath: importPath,
      className: className,
      dependencies: constructorParams,
      factoryMethod: null, //* We dont have a factory method here
      namedArgs: namedArgs,
      name: attributes.name,
      key: attributes.key,
      environment: attributes.environment,
    );
  }

  static LazyData _collectLazyData(
    MethodElement method,
    BuildStep buildStep,
    ConstantReader annotationReader,
    ClassElement element,
  ) {
    var returnTypeElement = method.returnType.element;
    if (returnTypeElement is! ClassElement) {
      throw Exception("Return type of the lazy is not a class.");
    }

    // Get the super classes of the class
    final Set<SuperTypeData> superClasses =
        ClassHierarchyExplorer.explore(returnTypeElement, buildStep);

    // Get the import path of the class
    final ImportPath importPath =
        ImportPathResolver.determineImportPathForClass(
            returnTypeElement, buildStep);

    // Get the class name
    final className =
        method.returnType.getDisplayString(withNullability: false);

    // Get the constructor parameters of the class
    final List<String> constructorParams =
        ConstructorProcessor.getConstructorParams(returnTypeElement);

    final returnType = element.name;

    // Get the annotation attributes
    final AnnotationAttributes attributes =
        AnnotationProcessor.getAnnotationAttributes(element);

    return LazyData(
      importPath: importPath,
      className: className,
      returnType: returnType,
      dependencies: constructorParams,
      interfaces: superClasses.toList(),
      name: attributes.name,
      key: attributes.key,
      environment: attributes.environment,
    );
  }

  static Set<ImportPath> _collectImportPathsFromReturnType(
    ExecutableElement executableElement,
    BuildStep buildStep,
  ) {
    final Set<ImportPath> importPaths = {};

    var returnTypeElement = executableElement.returnType.element;
    if (returnTypeElement is ClassElement) {
      final importPath = ImportPathResolver.determineImportPathForClass(
          returnTypeElement, buildStep);

      importPaths.add(importPath);
    }

    return importPaths;
  }

  static Set<ImportPath> _collectImportPathsFromParameters(
    MethodElement method,
    BuildStep buildStep,
  ) {
    final Set<ImportPath> importPaths = {};

    for (var parameter in method.parameters) {
      var parameterElement = parameter.type.element;
      if (parameterElement is ClassElement) {
        final importPath = ImportPathResolver.determineImportPathForClass(
            parameterElement, buildStep);

        importPaths.add(importPath);
      }
    }

    return importPaths;
  }
}
