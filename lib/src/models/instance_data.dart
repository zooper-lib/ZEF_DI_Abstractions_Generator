class InstanceData {
  final String importPath;
  final String className;
  final List<String> dependencies;
  final List<String> interfaces;
  final String? name;
  final dynamic key;
  final String? environment;

  InstanceData({
    required this.importPath,
    required this.className,
    required this.dependencies,
    required this.interfaces,
    this.name,
    this.key,
    this.environment,
  });

  factory InstanceData.fromJson(Map<String, dynamic> json) {
    return InstanceData(
      importPath: json['importPath'],
      className: json['className'],
      dependencies: List<String>.from(json['dependencies']),
      interfaces: List<String>.from(json['interfaces']),
      name: json['name'],
      key: json['key'],
      environment: json['environment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'importPath': importPath,
      'className': className,
      'dependencies': dependencies,
      'interfaces': interfaces,
      'name': name,
      'key': key,
      'environment': environment,
    };
  }
}
