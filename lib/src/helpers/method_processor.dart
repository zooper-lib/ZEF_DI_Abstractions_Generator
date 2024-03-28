import 'package:analyzer/dart/element/element.dart';

class MethodProcessor {
  static Map<String, String> getNamedParameters(ExecutableElement method) {
    return Map.fromEntries(method.parameters
        .where((param) => param.isNamed)
        .map((param) => MapEntry(
            param.name, param.type.getDisplayString(withNullability: false))));
  }

  static List<String> getUnnamedParameters(ExecutableElement method) {
    final unnamedParams = method.parameters
        .where((param) => !param.isNamed)
        .map((param) => param.type.getDisplayString(withNullability: false))
        .toList();

    print('Unnamed method params: $unnamedParams');

    return unnamedParams;
  }
}
