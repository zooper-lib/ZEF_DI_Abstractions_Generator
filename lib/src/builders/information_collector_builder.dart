import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
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

    final library = await buildStep.inputLibrary;
    final annotations = LibraryReader(library)
        .annotatedWith(TypeChecker.fromRuntime(Registration));

    final List<RegistrationData> collectedRegistrations = [];

    for (var annotatedElement in annotations) {
      final element = annotatedElement.element;
      final annotation = annotatedElement.annotation;

      if (element is! ClassElement) continue;

      if (_isRegisterInstanceAnnotation(annotation)) {
        collectedRegistrations.add(_collectInstanceData(element));
        print('Collected instance data for ${element.name}');
      } else if (_isRegisterFactoryAnnotation(annotation)) {
        collectedRegistrations.add(_collectFactoryData(element));
        print('Collected factory data for ${element.name}');
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

  InstanceData _collectInstanceData(ClassElement element) {
    // Collect and return data for an instance registration
    List<String> constructorParams = _getConstructorParams(element);
    return InstanceData(
      importPath: element.librarySource.uri.toString(),
      className: element.name,
      dependencies: constructorParams,
      interfaces: [], // Collect interfaces if needed
    );
  }

  FactoryData _collectFactoryData(ClassElement element) {
    List<String> constructorParams = _getConstructorParams(element);
    String? factoryMethodName = _findAnnotatedFactoryMethodName(element);

    // Collect and return data for a factory registration
    return FactoryData(
      importPath: element.librarySource.uri.toString(),
      className: element.name,
      dependencies: constructorParams,
      factoryMethod: factoryMethodName,
      interfaces: [], // Collect interfaces if needed
      // Add other fields as necessary
    );
  }

  String? _findAnnotatedFactoryMethodName(ClassElement element) {
    // Implement logic to find a method annotated to act as the factory
    // Return the method name if found, otherwise return null
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

  Future<void> _writeCollectedData(
      BuildStep buildStep, List<RegistrationData> registrations) async {
    if (registrations.isNotEmpty) {
      final jsonList =
          registrations.map((registration) => registration.toJson()).toList();
      await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.info.json'),
        json.encode(jsonList),
      );
    }
  }
}
