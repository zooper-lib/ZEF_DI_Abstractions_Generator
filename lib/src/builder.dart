import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zef_di_abstractions_generator/src/generators/injection_generator.dart';

import 'builders/code_generator_builder.dart';
import 'builders/information_collector_builder.dart';

Builder informationCollectorBuilder(BuilderOptions options) =>
    InformationCollectorBuilder();

Builder codeGeneratorBuilder(BuilderOptions options) => CodeGeneratorBuilder();

// Builder dependencyBuilder(BuilderOptions options) =>
//     LibraryBuilder(InjectionGenerator(), generatedExtension: '.generated.dart');
