import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';
import 'package:zef_di_abstractions_generator/src/models/instance_data.dart';

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
        .annotatedWith(TypeChecker.fromRuntime(RegisterInstance));
    final List<InstanceData> collectedInfos = [];

    for (var annotatedElement in annotations) {
      final element = annotatedElement.element;
      if (element is! ClassElement) continue;

      // Determine the constructor parameters for the default constructor
      List<String> constructorParams = [];
      ConstructorElement? defaultConstructor = element.unnamedConstructor;
      if (defaultConstructor != null) {
        constructorParams = defaultConstructor.parameters
            .where((param) => !param
                .isNamed) // Focus on non-named parameters as per your requirement
            .map((param) => param.type.getDisplayString(withNullability: false))
            .toList();
      }

      // Create an instance of CollectedClassInfo for each class
      var collectedInfo = InstanceData(
        importPath: element.librarySource.uri.toString(),
        className: element.name,
        dependencies: constructorParams,
        interfaces: [],
        name: null,
        key: null,
        environment: null,
      );

      collectedInfos.add(collectedInfo);
    }

    // Serialize each CollectedClassInfo to JSON
    List<Map<String, dynamic>> jsonList =
        collectedInfos.map((info) => info.toJson()).toList();

    // Only write the file if there's actually something to write
    if (jsonList.isNotEmpty) {
      await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.info.json'),
        json.encode(jsonList),
      );
    }
  }
}
