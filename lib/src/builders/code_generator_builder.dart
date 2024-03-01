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

    final List<InstanceData> allInstanceData =
        await _readAllInstanceData(buildStep);

    // Analyze dependencies and topologically sort the instances
    // This part of the implementation depends on how you choose to represent and sort the dependency graph
    final List<InstanceData> sortedInstances =
        _topologicallySortInstances(allInstanceData);

    // Generate the code
    _writeHeader(codeBuffer);
    _writeImports(codeBuffer, importPaths);
    _writeRegistrationFunctionStart(codeBuffer);
    _writeRegistrationFunction(codeBuffer, sortedInstances);
    _writeRegistrationFunctionEnd(codeBuffer);

    // Format the code
    final String formattedCode = _formatCode(codeBuffer.toString());

    // Write the generated file
    await _writeGeneratedFile(buildStep, formattedCode);
  }

  Future<List<InstanceData>> _readAllInstanceData(BuildStep buildStep) async {
    final List<InstanceData> instances = [];

    await for (final inputId in buildStep.findAssets(Glob('**/*.info.json'))) {
      final content = await buildStep.readAsString(inputId);
      final List<dynamic> jsonData = json.decode(content);

      for (final jsonItem in jsonData) {
        instances
            .add(InstanceData.fromJson(Map<String, dynamic>.from(jsonItem)));
      }
    }

    return instances;
  }

  List<InstanceData> _topologicallySortInstances(List<InstanceData> instances) {
    // Build the graph
    final Map<String, Set<String>> graph = {};
    final Map<String, InstanceData> instanceLookup = {};

    // Initialize graph and lookup table
    for (var instance in instances) {
      graph[instance.className] = instance.dependencies.toSet();
      instanceLookup[instance.className] = instance;
    }

    // Perform topological sort
    final List<String> sortedClassNames = _performTopologicalSort(graph);

    // Map sorted class names back to their corresponding InstanceData
    final List<InstanceData> sortedInstances = [];
    for (var className in sortedClassNames) {
      if (instanceLookup.containsKey(className)) {
        sortedInstances.add(instanceLookup[className]!);
      }
    }

    return sortedInstances;
  }

  List<String> _performTopologicalSort(Map<String, Set<String>> graph) {
    final List<String> sorted = [];
    final Set<String> visited = {};
    final Set<String> visiting = {};

    void visit(String node) {
      if (visited.contains(node)) return;
      if (visiting.contains(node)) {
        throw Exception('Cyclic dependency detected in $node');
      }

      visiting.add(node);
      for (var dep in graph[node]!) {
        visit(dep);
      }
      visiting.remove(node);
      visited.add(node);
      sorted.add(node);
    }

    graph.keys.forEach(visit);
    return sorted;
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

        String registration;
        if (instanceData.dependencies.isEmpty) {
          // No dependencies, simple registration
          registration =
              "ServiceLocator.I.registerInstance<${instanceData.className}>(${instanceData.className}());";
        } else {
          // Resolve dependencies
          String resolvedParams = instanceData.dependencies
              .map((param) => "ServiceLocator.I.resolve<$param>()")
              .join(', ');

          registration =
              "ServiceLocator.I.registerInstance<${instanceData.className}>(${instanceData.className}($resolvedParams));";
        }
        registrationSnippets.add(registration);
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
      StringBuffer buffer, List<InstanceData> sortedInstances) {
    for (var instance in sortedInstances) {
      // Start the registration line
      String registrationLine =
          "ServiceLocator.I.registerInstance<${instance.className}>(";

      // If there are dependencies, resolve them within the constructor call
      if (instance.dependencies.isNotEmpty) {
        String resolvedDependencies = instance.dependencies
            .map((dep) => "ServiceLocator.I.resolve<$dep>()")
            .join(', ');
        registrationLine += "${instance.className}($resolvedDependencies)";
      } else {
        // No dependencies, just instantiate the class
        registrationLine += "${instance.className}()";
      }

      // Close the registration line
      registrationLine += ");";

      // Write the registration line to the buffer
      buffer.writeln(registrationLine);
    }
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
