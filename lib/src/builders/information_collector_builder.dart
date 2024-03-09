import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

import '../models/registrations.dart';

class InformationCollectorBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.info.json']
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;

    final LibraryElement library = await buildStep.inputLibrary;
    final List<RegistrationData> collectedRegistrations = [];

    for (var element in library.topLevelElements) {
      if (element is ClassElement) {
        bool isRegisterInstance = false;
        bool isRegisterFactory = false;
        bool isRegisterLazy = false;

        for (var annotation in element.metadata) {
          var annotationReader =
              ConstantReader(annotation.computeConstantValue());
          if (_isRegisterInstanceAnnotation(annotationReader)) {
            isRegisterInstance = true;
            break;
          } else if (_isRegisterFactoryAnnotation(annotationReader)) {
            isRegisterFactory = true;
          } else if (_isRegisterLazyAnnotation(annotationReader)) {
            isRegisterLazy = true;
          }
        }

        if (isRegisterInstance) {
          collectedRegistrations.add(_collectInstanceData(element));
        } else if (isRegisterFactory) {
          collectedRegistrations.add(_collectFactoryData(element));
        } else if (isRegisterLazy) {
          collectedRegistrations.add(_collectLazyData(element));
        }
      }
    }

    // Serialize and write the collected registration data
    await _writeCollectedData(buildStep, collectedRegistrations);
  }

  bool _isRegisterInstanceAnnotation(ConstantReader annotation) {
    return TypeChecker.fromRuntime(RegisterInstance)
        .isExactlyType(annotation.objectValue.type!);
  }

  bool _isRegisterFactoryAnnotation(ConstantReader annotation) {
    return TypeChecker.fromRuntime(RegisterFactory)
        .isExactlyType(annotation.objectValue.type!);
  }

  bool _isRegisterLazyAnnotation(ConstantReader annotation) {
    return TypeChecker.fromRuntime(RegisterLazy)
        .isExactlyType(annotation.objectValue.type!);
  }

  InstanceData _collectInstanceData(ClassElement element) {
    final Set<SuperTypeData> superClasses = _exploreClassHierarchy(element, {});
    final List<String> constructorParams = _getConstructorParams(element);
    final _AnnotationAttributes attributes = _getAnnotationAttributes(element);

    return InstanceData(
      importPath: element.librarySource.uri.toString(),
      className: element.name,
      dependencies: constructorParams,
      interfaces: superClasses.toList(),
      name: attributes.name,
      key: attributes.key,
      environment: attributes.environment,
    );
  }

  FactoryData _collectFactoryData(ClassElement element) {
    final Set<SuperTypeData> superClasses = _exploreClassHierarchy(element, {});
    List<String> constructorParams = _getConstructorParams(element);
    String? factoryMethodName = _findAnnotatedFactoryMethodName(element);
    Map<String, String> namedArgs = {};
    final _AnnotationAttributes attributes = _getAnnotationAttributes(element);

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
      importPath: element.librarySource.uri.toString(),
      className: element.name,
      dependencies: constructorParams,
      factoryMethod: factoryMethodName,
      namedArgs: namedArgs,
      name: attributes.name,
      key: attributes.key,
      environment: attributes.environment,
    );
  }

  LazyData _collectLazyData(ClassElement element) {
    final Set<SuperTypeData> superClasses = _exploreClassHierarchy(element, {});
    final _AnnotationAttributes attributes = _getAnnotationAttributes(element);
    final List<String> constructorParams = _getConstructorParams(element);

    final returnType = element.name;

    return LazyData(
      importPath: element.librarySource.uri.toString(),
      className: element.name,
      returnType: returnType,
      dependencies: constructorParams,
      interfaces: superClasses.toList(),
      name: attributes.name,
      key: attributes.key,
      environment: attributes.environment,
    );
  }

  String? _findAnnotatedFactoryMethodName(ClassElement element) {
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

  List<String> _getConstructorParams(ClassElement element) {
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

  Map<String, String> _getNamedParameters(ExecutableElement method) {
    return Map.fromEntries(method.parameters
        .where((param) => param.isNamed)
        .map((param) => MapEntry(
            param.name, param.type.getDisplayString(withNullability: false))));
  }

  Map<String, String> _getNamedParametersFromConstructor(
      ConstructorElement constructor) {
    return Map.fromEntries(constructor.parameters
        .where((param) => param.isNamed)
        .map((param) => MapEntry(
            param.name, param.type.getDisplayString(withNullability: false))));
  }

  _AnnotationAttributes _getAnnotationAttributes(ClassElement element) {
    for (var annotation in element.metadata) {
      var annotationReader = ConstantReader(annotation.computeConstantValue());
      if (_isRegisterInstanceAnnotation(annotationReader) ||
          _isRegisterFactoryAnnotation(annotationReader)) {
        final String? name = annotationReader.read('_name').isNull
            ? null
            : annotationReader.read('_name').stringValue;
        final dynamic key = annotationReader.read('_key').isNull
            ? null
            : annotationReader.read('_key').literalValue;
        final String? environment = annotationReader.read('_environment').isNull
            ? null
            : annotationReader.read('_environment').stringValue;

        return _AnnotationAttributes(
            name: name, key: key, environment: environment);
      }
    }
    return _AnnotationAttributes();
  }

  Future<void> _writeCollectedData(
      BuildStep buildStep, List<RegistrationData> registrations) async {
    if (registrations.isNotEmpty) {
      final jsonList =
          registrations.map((registration) => registration.toJson()).toList();

      final jsonString = json.encode(jsonList);

      await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.info.json'),
        jsonString,
      );
    }
  }

  Set<SuperTypeData> _exploreClassHierarchy(
      ClassElement classElement, Set<SuperTypeData> visitedClasses) {
    // Avoid processing the same class more than once
    if (visitedClasses.any((element) =>
        element.className == classElement.name &&
        element.importPath == classElement.librarySource.uri.toString())) {
      return visitedClasses;
    }

    visitedClasses.add(
      SuperTypeData(
        importPath: classElement.librarySource.uri.toString(),
        className: classElement.name,
      ),
    );

    // Explore the superclass
    InterfaceType? supertype = classElement.supertype;
    if (supertype != null) {
      Element? superclassElement = supertype.element;
      if (superclassElement is ClassElement) {
        _exploreClassHierarchy(superclassElement, visitedClasses);
      }
    }

    // Explore the implemented interfaces
    for (InterfaceType interfaceType in classElement.interfaces) {
      Element interfaceElement = interfaceType.element;
      if (interfaceElement is ClassElement) {
        _exploreClassHierarchy(interfaceElement, visitedClasses);
      }
    }

    return visitedClasses;
  }
}

class _AnnotationAttributes {
  final String? name;
  final dynamic key;
  final String? environment;

  _AnnotationAttributes({this.name, this.key, this.environment});
}
