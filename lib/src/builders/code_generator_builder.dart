import 'dart:async';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:convert';

import 'package:glob/glob.dart';
import 'package:zef_di_abstractions_generator/src/helpers/sort_helper.dart';

import '../models/registrations.dart';

class CodeGeneratorBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
        r'$lib$': ['dependency_registration.g.dart']
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final codeBuffer = StringBuffer();
    final importPaths = await _collectImportPaths(buildStep);
    final allRegistrations = await _readAndSortRegistrationData(buildStep);

    _writeHeader(codeBuffer);
    _writeImports(codeBuffer, importPaths);
    _writeRegistrationFunctions(codeBuffer, allRegistrations);

    await _writeGeneratedFile(buildStep, codeBuffer.toString());
  }

  Future<Set<String>> _collectImportPaths(BuildStep buildStep) async {
    final importPaths = {
      'package:zef_di_abstractions/zef_di_abstractions.dart',
      'package:zef_helpers_lazy/zef_helpers_lazy.dart'
    };

    await for (final inputId in buildStep.findAssets(Glob('**/*.info.json'))) {
      final content = await buildStep.readAsString(inputId);
      final jsonData = json.decode(content) as List<dynamic>;

      for (var jsonItem in jsonData) {
        final info =
            RegistrationData.fromJson(Map<String, dynamic>.from(jsonItem));

        // Add the import path of the RegistrationData itself, if it's a package
        if (Uri.parse(info.importPath).scheme == 'package') {
          importPaths.add(info.importPath);
        }

        // Add import paths from all SuperTypeData instances in the interfaces list
        for (final interface in info.interfaces) {
          if (Uri.parse(interface.importPath).scheme == 'package') {
            importPaths.add(interface.importPath);
          }
        }
      }
    }

    return importPaths;
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

  void _writeImports(StringBuffer buffer, Set<String> importPaths) {
    for (var path in importPaths) {
      buffer.writeln("import '$path';");
    }
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
    final dependencies = instance.dependencies
        .map((d) => "ServiceLocator.I.resolve<$d>(),")
        .join();

    final interfaces = instance.interfaces.isNotEmpty
        ? "interfaces: [${instance.interfaces.map((i) => i.className).join(', ')}]"
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
        ? "interfaces: [${factory.interfaces.map((i) => i.className).join(', ')}]"
        : "interfaces: null";

    final name =
        factory.name != null ? "name: '${factory.name}'" : 'name: null';

    final key = factory.key != null ? "key: ${factory.key}" : 'key: null';

    final environment = factory.environment != null
        ? "environment: '${factory.environment}'"
        : 'environment: null';

    // Initialize the dependencies resolution string for unnamed parameters
    String dependencies = factory.dependencies
        .map((dep) => "serviceLocator.resolve<$dep>(namedArgs: namedArgs)")
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
    final dependencies = lazyData.dependencies
        .map((d) => "ServiceLocator.I.resolve<$d>(), ")
        .join();

    final interfaces = lazyData.interfaces.isNotEmpty
        ? "interfaces: [${lazyData.interfaces.map((i) => i.className).join(', ')}]"
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
