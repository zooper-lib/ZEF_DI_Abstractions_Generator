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
        r'$lib$': ['service_locator.g.dart']
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
      'package:zef_di_abstractions/zef_di_abstractions.dart'
    };

    await for (final inputId in buildStep.findAssets(Glob('**/*.info.json'))) {
      final content = await buildStep.readAsString(inputId);
      final jsonData = json.decode(content) as List<dynamic>;

      for (var jsonItem in jsonData) {
        final info = RegistrationData.fromJson(Map<String, dynamic>.from(
            jsonItem)); // Use RegistrationData for deserialization
        if (Uri.parse(info.importPath).scheme == 'package') {
          importPaths.add(info.importPath);
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
        if (data.containsKey('dependencies')) {
          // Assuming dependencies indicate an InstanceData
          registrations.add(InstanceData.fromJson(data));
        } else if (data.containsKey('factoryMethod')) {
          // Assuming factoryMethod indicates a FactoryData
          registrations.add(FactoryData.fromJson(data));
        }
      }
    }

    // Sort the registrations if necessary, mainly based on dependencies for InstanceData
    // Assuming a method _topologicallySortRegistrations exists that can handle sorting
    return SortHelper.topologicallySortRegistrations(registrations);
  }

  // Implement _topologicallySortRegistrations based on your dependency analysis and sorting strategy

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
      StringBuffer buffer, List<RegistrationData> registrations) {
    buffer.writeln("void registerGeneratedDependencies() {");

    for (var registration in registrations) {
      if (registration is InstanceData) {
        buffer.writeln(_generateInstanceRegistration(registration));
      } else if (registration is FactoryData) {
        buffer.writeln(_generateFactoryRegistration(registration));
      }
    }

    buffer.writeln("}");
  }

  String _generateInstanceRegistration(InstanceData instance) {
    final dependencies = instance.dependencies
        .map((d) => "ServiceLocator.I.resolve<$d>()")
        .join(', ');
    return "  ServiceLocator.I.registerInstance<${instance.className}>(${instance.className}(${dependencies.isNotEmpty ? dependencies : ''}));";
  }

  String _generateFactoryRegistration(FactoryData factory) {
    String registrationCode;

    if (factory.factoryMethod != null) {
      // For factory methods, resolve dependencies within the method call
      String dependencies = factory.dependencies
          .map((dep) => "ServiceLocator.I.resolve<$dep>()")
          .join(', ');
      registrationCode =
          "ServiceLocator.I.registerFactory<${factory.className}>(() => ${factory.className}.${factory.factoryMethod}($dependencies));";
    } else {
      // For default constructors, resolve dependencies within the constructor call
      String dependencies = factory.dependencies
          .map((dep) => "ServiceLocator.I.resolve<$dep>()")
          .join(', ');
      registrationCode =
          "ServiceLocator.I.registerFactory<${factory.className}>(() => ${factory.className}($dependencies));";
    }

    return registrationCode;
  }

  Future<void> _writeGeneratedFile(BuildStep buildStep, String content) async {
    final formattedContent = _formatCode(content);
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/service_locator.g.dart'),
      formattedContent,
    );
  }

  String _formatCode(String code) {
    final formatter = DartFormatter();
    return formatter.format(code);
  }
}
