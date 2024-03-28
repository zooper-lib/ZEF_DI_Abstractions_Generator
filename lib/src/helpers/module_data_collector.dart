import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
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
    /* for (var method in element.methods) {
      registrations.addAll(_collectFromModuleMethod(method, buildStep));
      importPaths.addAll(_collectImportPathsFromReturnType(method, buildStep));
      importPaths.addAll(_collectImportPathsFromParameters(method, buildStep));
    }

    // Extend to collect registration data and import paths from instances, aka getters
    element.accessors.where((accessor) => accessor.isGetter).forEach((getter) {
      registrations.addAll(_collectFromModuleGetter(getter, buildStep));
      importPaths.addAll(_collectImportPathsFromReturnType(getter, buildStep));
    }); */

    // Collect from getters and methods for both singletons and transients
    for (var accessor
        in element.accessors.where((accessor) => accessor.isGetter)) {
      var registration = _collectFromAccessor(accessor, buildStep);
      if (registration != null) {
        registrations.add(registration);
        importPaths.add(ImportPathResolver.determineImportPathForClass(
            accessor.returnType.element as ClassElement, buildStep));
      }
    }

    for (var method in element.methods.where((method) => !method.isAbstract)) {
      var registration = _collectFromMethod(method, buildStep);
      if (registration != null) {
        registrations.add(registration);
        importPaths.add(ImportPathResolver.determineImportPathForClass(
            method.returnType.element as ClassElement, buildStep));
        for (var param in method.parameters) {
          if (param.type.element is ClassElement) {
            importPaths.add(ImportPathResolver.determineImportPathForClass(
                param.type.element as ClassElement, buildStep));
          }
        }
      }
    }

    return ModuleRegistration(
      registrations: registrations,
      importPaths: importPaths,
    );
  }

  static TypeRegistration? _collectFromAccessor(
      PropertyAccessorElement accessor, BuildStep buildStep) {
    var annotationReader = accessor.metadata
        .map((m) => ConstantReader(m.computeConstantValue()))
        .firstWhereOrNull(
          (reader) =>
              AnnotationProcessor.isRegisterSingleton(reader) ||
              AnnotationProcessor.isRegisterTransient(reader),
        );
    if (annotationReader == null) {
      return null;
    }

    return _collectRegistrationData(accessor, buildStep, annotationReader);
  }

  static TypeRegistration? _collectFromMethod(
      MethodElement method, BuildStep buildStep) {
    var annotationReader = method.metadata
        .map((m) => ConstantReader(m.computeConstantValue()))
        .firstWhereOrNull(
          (reader) =>
              AnnotationProcessor.isRegisterSingleton(reader) ||
              AnnotationProcessor.isRegisterTransient(reader),
        );

    // If there is no annotation, return null
    if (annotationReader == null) {
      return null;
    }

    return _collectRegistrationData(method, buildStep, annotationReader);
  }

  static TypeRegistration _collectRegistrationData(ExecutableElement element,
      BuildStep buildStep, ConstantReader annotationReader) {
    var returnTypeElement = element.returnType.element;
    if (returnTypeElement is! ClassElement) {
      throw Exception("The return type of the element is not a class.");
    }

    final isSingleton =
        AnnotationProcessor.isRegisterSingleton(annotationReader);
    final isTransient =
        AnnotationProcessor.isRegisterTransient(annotationReader);
    final isLazy = AnnotationProcessor.isRegisterLazy(annotationReader);

    // Get the factory method name, if any
    String? factoryConstructorName =
        ConstructorProcessor.getConstructorName(returnTypeElement);

    // Get the super classes of the class
    final Set<SuperTypeData> superTypes =
        ClassHierarchyExplorer.explore(returnTypeElement, buildStep);

    // Get the import path of the class
    final ImportPath importPath =
        ImportPathResolver.determineImportPathForClass(
            returnTypeElement, buildStep);

    // Get the annotation attributes
    final AnnotationAttributes attributes =
        AnnotationProcessor.getAnnotationAttributes(element);

    // Get the dependencies
    final List<String> dependencies = _collectDependencies(element);

    // Get the named arguments
    final Map<String, String> namedArgs = _collectNamedArgs(element);

    if (isSingleton) {
      return SingletonData(
        importPath: importPath,
        className: returnTypeElement.name,
        factoryMethodName: factoryConstructorName,
        dependencies: dependencies,
        namedArgs: namedArgs,
        interfaces: superTypes.toList(),
        name: attributes.name,
        key: attributes.key,
        environment: attributes.environment,
      );
    } else if (isTransient) {
      return TransientData(
        importPath: importPath,
        className: returnTypeElement.name,
        factoryMethodName: factoryConstructorName,
        dependencies: dependencies,
        namedArgs: namedArgs,
        interfaces: superTypes.toList(),
        name: attributes.name,
        key: attributes.key,
        environment: attributes.environment,
      );
    } else if (isLazy) {
      return LazyData(
        importPath: importPath,
        className: returnTypeElement.name,
        returnType: returnTypeElement.name,
        dependencies: dependencies,
        interfaces: superTypes.toList(),
        name: attributes.name,
        key: attributes.key,
        environment: attributes.environment,
      );
    } else {
      throw Exception("Unknown registration type.");
    }
  }

  static List<String> _collectDependencies(ExecutableElement element) {
    if (element is MethodElement) {
      // Collecting dependencies from method parameters
      return element.parameters
          .where((p) => !p.isNamed)
          .map((p) => p.type.getDisplayString(withNullability: false))
          .toList();
    } else if (element is PropertyAccessorElement &&
        element.returnType.element is ClassElement) {
      // Collecting dependencies from the constructor of the return type of a getter
      var returnTypeElement = element.returnType.element as ClassElement;
      return ConstructorProcessor.getConstructorParams(returnTypeElement);
    } else {
      return [];
    }
  }

  // Method to collect named arguments from a module method
  static Map<String, String> _collectNamedArgs(ExecutableElement element) {
    if (element is MethodElement) {
      // Collecting named arguments from method parameters
      return {
        for (var param in element.parameters.where((p) => p.isNamed))
          param.name: param.type.getDisplayString(withNullability: false)
      };
    } else if (element is PropertyAccessorElement &&
        element.returnType.element is ClassElement) {
      // Collecting named arguments from the constructor of the return type of a getter
      var returnTypeElement = element.returnType.element as ClassElement;
      return ConstructorProcessor.getNamedParameters(returnTypeElement);
    } else {
      return {};
    }
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

  static void _collectImportPathsForExecutable(ExecutableElement executable,
      BuildStep buildStep, Set<ImportPath> importPaths) {
    // Collect import path for the return type
    var returnTypeElement = executable.returnType.element;
    if (returnTypeElement is ClassElement) {
      importPaths.add(ImportPathResolver.determineImportPathForClass(
          returnTypeElement, buildStep));
    }

    // Collect import paths for parameter types
    for (var parameter in executable.parameters) {
      var parameterTypeElement = parameter.type.element;
      if (parameterTypeElement is ClassElement) {
        importPaths.add(ImportPathResolver.determineImportPathForClass(
            parameterTypeElement, buildStep));
      }
    }
  }
}
