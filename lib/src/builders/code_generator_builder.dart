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
    final codeBuffer = StringBuffer();
    final importPaths = await _collectImportPaths(buildStep);
    final sortedInstances = await _getSortedInstances(buildStep);

    _writeHeader(codeBuffer);
    _writeImports(codeBuffer, importPaths);
    _writeRegistrationFunction(codeBuffer, sortedInstances);

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
        final info = InstanceData.fromJson(Map<String, dynamic>.from(jsonItem));
        if (Uri.parse(info.importPath).scheme == 'package') {
          importPaths.add(info.importPath);
        }
      }
    }

    return importPaths;
  }

  Future<List<InstanceData>> _getSortedInstances(BuildStep buildStep) async {
    final instances = await _readAllInstanceData(buildStep);
    return _topologicallySortInstances(instances);
  }

  Future<List<InstanceData>> _readAllInstanceData(BuildStep buildStep) async {
    final instances = <InstanceData>[];

    await for (final inputId in buildStep.findAssets(Glob('**/*.info.json'))) {
      final content = await buildStep.readAsString(inputId);
      final jsonData = json.decode(content) as List<dynamic>;

      instances.addAll(jsonData.map((jsonItem) =>
          InstanceData.fromJson(Map<String, dynamic>.from(jsonItem))));
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

  void _writeRegistrationFunction(
      StringBuffer buffer, List<InstanceData> sortedInstances) {
    buffer.writeln("void registerGeneratedDependencies() {");

    for (var instance in sortedInstances) {
      final dependencies = instance.dependencies
          .map((d) => "ServiceLocator.I.resolve<$d>()")
          .join(', ');
      final registrationLine =
          "  ServiceLocator.I.registerInstance<${instance.className}>(${instance.className}(${dependencies.isNotEmpty ? dependencies : ''}));";
      buffer.writeln(registrationLine);
    }

    buffer.writeln("}\n");
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
