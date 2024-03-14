import 'package:source_gen/source_gen.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

class AnnotationProcessor {
  static bool isRegisterInstance(ConstantReader annotation) =>
      TypeChecker.fromRuntime(RegisterInstance)
          .isExactlyType(annotation.objectValue.type!);

  static bool isRegisterFactory(ConstantReader annotation) =>
      TypeChecker.fromRuntime(RegisterFactory)
          .isExactlyType(annotation.objectValue.type!);

  static bool isRegisterLazy(ConstantReader annotation) =>
      TypeChecker.fromRuntime(RegisterLazy)
          .isExactlyType(annotation.objectValue.type!);
}
