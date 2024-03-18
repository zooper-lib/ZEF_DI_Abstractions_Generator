import 'package:analyzer/dart/element/element.dart';

class ConstructorProcessor {
  static Map<String, String> getNamedParameters(
      ConstructorElement constructor) {
    return Map.fromEntries(constructor.parameters
        .where((param) => param.isNamed)
        .map((param) => MapEntry(
            param.name, param.type.getDisplayString(withNullability: false))));
  }

  static List<String> getConstructorParams(ClassElement element) {
    // Attempt to find the default constructor; if not found, use the first constructor as a fallback
    final ConstructorElement constructor =
        element.unnamedConstructor ?? element.constructors.first;

    // Use null-aware operators to handle the case where the constructor might be null
    return constructor.parameters
        .where((param) => !param.isNamed) // exclude named parameters
        .map((param) => param.type.getDisplayString(withNullability: false))
        .toList(); // Provide an empty list as a fallback if 'constructor' is null
  }
}
