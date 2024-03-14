import 'dart:async';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:convert';

import 'package:glob/glob.dart';
import 'package:zef_di_abstractions_generator/src/helpers/sort_helper.dart';

import '../models/import_path.dart';
import '../models/import_type.dart';
import '../models/registrations.dart';

class CodeGeneratorBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
        r'$lib$': ['dependency_registration.g.dart']
      };

  final Set<ImportPath> _importedPackages = {
    ImportPath(
      'zef_di_abstractions/zef_di_abstractions.dart',
      ImportType.package,
    ),
    ImportPath(
      'zef_helpers_lazy/zef_helpers_lazy.dart',
      ImportType.package,
    ),
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final codeBuffer = StringBuffer();
    final allRegistrations = await _readAndSortRegistrationData(buildStep);

    _writeHeader(codeBuffer);
    _writeImports(codeBuffer, allRegistrations);
    _writeRegistrationFunctions(codeBuffer, allRegistrations);

    await _writeGeneratedFile(buildStep, codeBuffer.toString());
  }

  Future<List<RegistrationData>> _readAndSortRegistrationData(
      BuildStep buildStep) async {
    final registrations = <RegistrationData>[];

    await for (final inputId in buildStep.findAssets(Glob('**/*.info.json'))) {
      final content = await buildStep.readAsString(inputId);
      final jsonData = json.decode(content) as List<dynamic>;

      for (var jsonItem in jsonData) {
        final data = Map<String, dynamic>.from(jsonItem);

        final registration = RegistrationData.fromJson(data);
        registrations.add(registration);
      }
    }

    // Sort the registrations
    return SortHelper.topologicallySortRegistrations(registrations);
  }

  void _writeHeader(StringBuffer buffer) {
    buffer
      ..writeln("// GENERATED CODE - DO NOT MODIFY BY HAND")
      ..writeln(
          "// ******************************************************************************\n");
  }

  void _writeImports(
      StringBuffer buffer, List<RegistrationData> registrations) {
    final Set<ImportPath> uniqueImports = {};

    // Collect import paths from registrations
    for (var registration in registrations) {
      uniqueImports.add(registration.importPath);

      // Collect import paths from super types/interfaces
      for (var interface in registration.interfaces) {
        uniqueImports.add(interface.importPath);
      }
    }

    // Optionally, add any default or fixed imports your system requires
    for (var importPath in _importedPackages) {
      uniqueImports.add(importPath);
    }

    // Write the import statements
    for (var importPath in uniqueImports) {
      buffer.writeln(importPath.toString());
    }

    // Add an extra newline for separation
    buffer.writeln();
  }

  void _writeRegistrationFunctions(
    StringBuffer buffer,
    List<RegistrationData> registrations,
  ) {
    // Write the function signature
    buffer.writeln("void registerDependencies() {");

    for (var registration in registrations) {
      if (registration is InstanceData) {
        buffer.writeln(_generateInstanceRegistration(registration));
      } else if (registration is FactoryData) {
        buffer.writeln(_generateFactoryRegistration(registration));
      } else if (registration is LazyData) {
        buffer.writeln(_generateLazyRegistration(registration));
      }

      // Add a newline after each registration
      buffer.writeln();
    }

    buffer.writeln("}");
  }

  String _generateInstanceRegistration(InstanceData instance) {
    final dependencies =
        instance.dependencies.map((d) => "ServiceLocator.I.resolve(),").join();

    final interfaces = instance.interfaces.isNotEmpty
        ? "interfaces: {${instance.interfaces.map((i) => i.className).join(', ')}}"
        : "interfaces: null";

    final name =
        instance.name != null ? "name: '${instance.name}'" : 'name: null';

    final key = instance.key != null ? "key: ${instance.key}" : 'key: null';

    final environment = instance.environment != null
        ? "environment: '${instance.environment}'"
        : 'environment: null';

    return '''
        ServiceLocator.I.registerInstance<${instance.className}>(${instance.className}(
          ${dependencies.isNotEmpty ? dependencies : ''}),
          $interfaces,
          $name,
          $key,
          $environment,
        );''';
  }

  String _generateFactoryRegistration(FactoryData factory) {
    final interfaces = factory.interfaces.isNotEmpty
        ? "interfaces: {${factory.interfaces.map((i) => i.className).join(', ')}}"
        : "interfaces: null";

    final name =
        factory.name != null ? "name: '${factory.name}'" : 'name: null';

    final key = factory.key != null ? "key: ${factory.key}" : 'key: null';

    final environment = factory.environment != null
        ? "environment: '${factory.environment}'"
        : 'environment: null';

    // Initialize the dependencies resolution string for unnamed parameters
    String dependencies = factory.dependencies
        .map((dep) => "serviceLocator.resolve(namedArgs: namedArgs)")
        .join(', ');

    // Prepare the string for named arguments, if any
    String namedArgs = factory.namedArgs.entries
        .map((e) => "${e.key}: namedArgs['${e.key}'] as ${e.value},")
        .join();

    // Combine dependencies and named arguments, if needed
    String allArgs =
        [dependencies, namedArgs].where((arg) => arg.isNotEmpty).join(', ');

    // Check if there's a factory method specified
    if (factory.factoryMethod != null && factory.factoryMethod!.isNotEmpty) {
      // If a factory method is specified, use it in the registration code
      return '''
          ServiceLocator.I.registerFactory<${factory.className}>(
            (serviceLocator, namedArgs) => ${factory.className}.${factory.factoryMethod}(
              $allArgs),
              $interfaces,
              $name,
              $key,
              $environment,
          );
        '''
          .trim();
    } else {
      // If no factory method is specified, use the constructor with resolved dependencies and named arguments
      return '''
          ServiceLocator.I.registerFactory<${factory.className}>(
            (serviceLocator, namedArgs) => ${factory.className}(
              $allArgs),
              $interfaces,
              $name,
              $key,
              $environment,
          );
        '''
          .trim();
    }
  }

  String _generateLazyRegistration(LazyData lazyData) {
    // Resolve dependencies for the constructor parameters
    final dependencies =
        lazyData.dependencies.map((d) => "ServiceLocator.I.resolve(), ").join();

    final interfaces = lazyData.interfaces.isNotEmpty
        ? "interfaces: {${lazyData.interfaces.map((i) => i.className).join(', ')}}"
        : "interfaces: null";

    final name =
        lazyData.name != null ? "name: '${lazyData.name}'" : 'name: null';
    final key = lazyData.key != null ? "key: ${lazyData.key}" : 'key: null';
    final environment = lazyData.environment != null
        ? "environment: '${lazyData.environment}'"
        : 'environment: null';

    return '''
        ServiceLocator.I.registerLazy<${lazyData.className}>(
          Lazy<${lazyData.className}>(factory: () => ${lazyData.className}(${dependencies.isNotEmpty ? dependencies : ''}),),
          $interfaces,
          $name,
          $key,
          $environment,
        );''';
  }

  Future<void> _writeGeneratedFile(BuildStep buildStep, String content) async {
    final formattedContent = _formatCode(content);
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/dependency_registration.g.dart'),
      formattedContent,
    );
  }

  String _formatCode(String code) {
    final formatter = DartFormatter();
    return formatter.format(code);
  }
}
