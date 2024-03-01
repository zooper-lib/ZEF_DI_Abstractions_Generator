import 'dart:async';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:convert';

import 'package:glob/glob.dart';

import '../models/instance_data.dart';

class CodeGeneratorBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
        r'$lib$': ['service_locator.g.dart']
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final StringBuffer codeBuffer = StringBuffer();
    final Set<String> importPaths = await _collectImportPaths(buildStep);
    final Set<String> registrationSnippets =
        await _collectRegistrationSnippets(buildStep);

    // Generate the code
    _writeHeader(codeBuffer);
    _writeImports(codeBuffer, importPaths);
    _writeRegistrationFunctionStart(codeBuffer);
    _writeRegistrationFunction(codeBuffer, registrationSnippets);
    _writeRegistrationFunctionEnd(codeBuffer);

    // Format the code
    final String formattedCode = _formatCode(codeBuffer.toString());

    // Write the generated file
    await _writeGeneratedFile(buildStep, formattedCode);
  }

  Future<Set<String>> _collectImportPaths(BuildStep buildStep) async {
    final Set<String> importPaths = {};

    // Add the ServiceLocator import
    importPaths.add('package:zef_di_abstractions/zef_di_abstractions.dart');

    // Collect all the import paths from the info files
    await for (final inputId in buildStep.findAssets(Glob('**/*.info.json'))) {
      final content = await buildStep.readAsString(inputId);
      final List<dynamic> jsonData = json.decode(content);

      for (final jsonItem in jsonData) {
        final info = InstanceData.fromJson(Map<String, dynamic>.from(jsonItem));
        if (Uri.parse(info.importPath).scheme == 'package') {
          importPaths.add(info.importPath);
        }
      }
    }

    return importPaths;
  }

  Future<Set<String>> _collectRegistrationSnippets(BuildStep buildStep) async {
    final Set<String> registrationSnippets = {};

    await for (final inputId in buildStep.findAssets(Glob('**/*.info.json'))) {
      final content = await buildStep.readAsString(inputId);
      final List<dynamic> jsonData = json.decode(content);

      for (final jsonItem in jsonData) {
        final instanceData =
            InstanceData.fromJson(Map<String, dynamic>.from(jsonItem));
        // Prepare the registration code snippet for this instance
        String snippet =
            "ServiceLocator.I.registerInstance<${instanceData.className}>(${instanceData.className}());";
        registrationSnippets.add(snippet);
      }
    }

    return registrationSnippets;
  }

  void _writeHeader(StringBuffer buffer) {
    buffer.writeln("// GENERATED CODE - DO NOT MODIFY BY HAND");
    buffer.writeln(
        "// ******************************************************************************\n");
  }

  void _writeImports(StringBuffer buffer, Set<String> importPaths) {
    for (String importPath in importPaths) {
      buffer.writeln("import '$importPath';");
    }
    buffer.writeln(); // Add an empty line after imports for readability
  }

  void _writeRegistrationFunctionStart(StringBuffer buffer) {
    buffer.writeln("void registerGeneratedDependencies() {");
  }

  void _writeRegistrationFunction(
      StringBuffer buffer, Set<String> registrationSnippets) {
    registrationSnippets.forEach(buffer.writeln);
  }

  void _writeRegistrationFunctionEnd(StringBuffer buffer) {
    buffer.writeln("}\n");
  }

  String _formatCode(String code) {
    final DartFormatter formatter = DartFormatter();
    return formatter.format(code);
  }

  Future<void> _writeGeneratedFile(BuildStep buildStep, String content) async {
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/service_locator.g.dart'),
      content,
    );
  }
}
