abstract class RegistrationData {
  final String importPath;
  final String className;
  final List<String> interfaces;
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
      'importPath': importPath,
      'className': className,
      'interfaces': interfaces,
      'name': name,
      'key': key,
      'environment': environment,
    };
  }

  factory RegistrationData.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('dependencies')) {
      return InstanceData.fromJson(json);
    } else if (json.containsKey('factoryMethod')) {
      return FactoryData.fromJson(json);
    } else {
      throw Exception('Unknown RegistrationData type');
    }
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
    return InstanceData(
      importPath: json['importPath'],
      className: json['className'],
      dependencies: List<String>.from(json['dependencies']),
      interfaces: List<String>.from(json['interfaces'] ?? []),
      name: json['name'],
      key: json['key'],
      environment: json['environment'],
    );
  }
}

class FactoryData extends RegistrationData {
  final List<String> dependencies;
  final String? factoryMethod;

  FactoryData({
    required super.importPath,
    required super.className,
    this.dependencies = const [],
    this.factoryMethod,
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
    });
    return json;
  }

  factory FactoryData.fromJson(Map<String, dynamic> json) {
    return FactoryData(
      importPath: json['importPath'],
      className: json['className'],
      dependencies: List<String>.from(json['dependencies'] ?? []),
      factoryMethod: json['factoryMethod'],
      interfaces: List<String>.from(json['interfaces'] ?? []),
      name: json['name'],
      key: json['key'],
      environment: json['environment'],
    );
  }
}
