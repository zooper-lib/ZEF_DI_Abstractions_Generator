import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:zef_di_abstractions_generator/src/helpers/registration_data_collector.dart';
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
    final registrations = library.topLevelElements
        .whereType<ClassElement>()
        .expand((e) =>
            [RegistrationDataCollector.collectFromClassElement(e, buildStep)])
        .where((e) => e != null)
        .cast<RegistrationData>()
        .toList();

    // Serialize and write the collected registration data
    await _writeCollectedData(buildStep, registrations);
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
}
