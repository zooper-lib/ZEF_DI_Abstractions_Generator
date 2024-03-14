import 'package:zef_di_abstractions_generator/src/models/import_path.dart';

abstract class RegistrationData {
  final ImportPath importPath;
  final String className;
  final List<SuperTypeData> interfaces;
  final String? name;
  final dynamic key;
  final String? environment;

  RegistrationData({
    required this.importPath,
    required this.className,
    this.interfaces = const [],
    this.name,
    this.key,
    this.environment,
  });

  Map<String, dynamic> toJson() {
    return {
      'importPath': importPath.toJson(),
      'className': className,
      'interfaces': interfaces,
      'name': name,
      'key': key,
      'environment': environment,
    };
  }

  factory RegistrationData.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('factoryMethod')) {
      return FactoryData.fromJson(json);
    } else if (json.containsKey('returnType')) {
      return LazyData.fromJson(json);
    } else {
      return InstanceData.fromJson(json);
    }
  }

  bool isInstance() => this is InstanceData;
}

class SuperTypeData {
  final ImportPath importPath;
  final String className;

  SuperTypeData({
    required this.importPath,
    required this.className,
  });

  Map<String, dynamic> toJson() {
    return {
      'importPath': importPath.toJson(),
      'className': className,
    };
  }

  factory SuperTypeData.fromJson(Map<String, dynamic> json) {
    return SuperTypeData(
      importPath: ImportPath.fromJson(json['importPath']),
      className: json['className'],
    );
  }
}

class InstanceData extends RegistrationData {
  final List<String> dependencies;

  InstanceData({
    required super.importPath,
    required super.className,
    this.dependencies = const [],
    super.interfaces,
    super.name,
    super.key,
    super.environment,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({'dependencies': dependencies});
    return json;
  }

  factory InstanceData.fromJson(Map<String, dynamic> json) {
    List<SuperTypeData> interfaces =
        (json['interfaces'] as List<dynamic>? ?? [])
            .map((e) => SuperTypeData.fromJson(e as Map<String, dynamic>))
            .toList();

    return InstanceData(
      importPath: ImportPath.fromJson(json['importPath']),
      className: json['className'],
      dependencies: List<String>.from(json['dependencies']),
      interfaces: interfaces,
      name: json['name'],
      key: json['key'],
      environment: json['environment'],
    );
  }
}

class FactoryData extends RegistrationData {
  final List<String> dependencies;
  final String? factoryMethod;
  final Map<String, String> namedArgs;

  FactoryData({
    required super.importPath,
    required super.className,
    this.dependencies = const [],
    this.factoryMethod,
    this.namedArgs = const {},
    super.interfaces,
    super.name,
    super.key,
    super.environment,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'dependencies': dependencies,
      'factoryMethod': factoryMethod,
      'namedArgs': namedArgs,
    });
    return json;
  }

  factory FactoryData.fromJson(Map<String, dynamic> json) {
    List<SuperTypeData> interfaces =
        (json['interfaces'] as List<dynamic>? ?? [])
            .map((e) => SuperTypeData.fromJson(e as Map<String, dynamic>))
            .toList();

    return FactoryData(
      importPath: ImportPath.fromJson(json['importPath']),
      className: json['className'],
      dependencies: List<String>.from(json['dependencies'] ?? []),
      factoryMethod: json['factoryMethod'],
      namedArgs: Map<String, String>.from(json['namedArgs'] ?? {}),
      interfaces: interfaces,
      name: json['name'],
      key: json['key'],
      environment: json['environment'],
    );
  }
}

class LazyData extends RegistrationData {
  final List<String> dependencies;
  final String returnType;

  LazyData({
    required super.importPath,
    required super.className,
    required this.returnType,
    this.dependencies = const [],
    super.interfaces,
    super.name,
    super.key,
    super.environment,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'dependencies': dependencies,
      'returnType': returnType,
    });
    return json;
  }

  factory LazyData.fromJson(Map<String, dynamic> json) {
    List<SuperTypeData> interfaces =
        (json['interfaces'] as List<dynamic>? ?? [])
            .map((e) => SuperTypeData.fromJson(e as Map<String, dynamic>))
            .toList();

    return LazyData(
      importPath: ImportPath.fromJson(json['importPath']),
      className: json['className'],
      returnType: json['returnType'] as String,
      dependencies: List<String>.from(json['dependencies']),
      interfaces: interfaces,
      name: json['name'],
      key: json['key'],
      environment: json['environment'],
    );
  }
}
