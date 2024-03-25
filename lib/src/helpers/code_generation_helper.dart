import '../models/registrations.dart';

class CodeGenerationHelper {
  static String generateInstanceRegistration(SingletonData instance) {
    final dependencies =
        instance.dependencies.map((d) => "ServiceLocator.I.resolve(),").join();

    final interfaces = instance.interfaces.isNotEmpty
        ? "interfaces: {${instance.interfaces.map((i) => i.className).join(', ')}}"
        : "interfaces: null";

    final name =
        instance.name != null ? "name: '${instance.name}'" : 'name: null';

    final key = instance.key != null ? "key: ${instance.key}" : 'key: null';

    final environment = instance.environment != null
        ? "environment: '${instance.environment}'"
        : 'environment: null';

    return '''
        ServiceLocator.I.registerInstance<${instance.className}>(${instance.className}(
          ${dependencies.isNotEmpty ? dependencies : ''}),
          $interfaces,
          $name,
          $key,
          $environment,
        );''';
  }

  static String generateFactoryRegistration(TransientData factory) {
    final interfaces = factory.interfaces.isNotEmpty
        ? "interfaces: {${factory.interfaces.map((i) => i.className).join(', ')}}"
        : "interfaces: null";

    final name =
        factory.name != null ? "name: '${factory.name}'" : 'name: null';

    final key = factory.key != null ? "key: ${factory.key}" : 'key: null';

    final environment = factory.environment != null
        ? "environment: '${factory.environment}'"
        : 'environment: null';

    // Initialize the dependencies resolution string for unnamed parameters
    String dependencies = factory.dependencies
        .map((dep) => "serviceLocator.resolve(namedArgs: namedArgs)")
        .join(', ');

    // Prepare the string for named arguments, if any
    String namedArgs = factory.namedArgs.entries
        .map((e) => "${e.key}: namedArgs['${e.key}'] as ${e.value},")
        .join();

    // Combine dependencies and named arguments, if needed
    String allArgs =
        [dependencies, namedArgs].where((arg) => arg.isNotEmpty).join(', ');

    // Check if there's a factory method specified
    if (factory.factoryMethodName != null &&
        factory.factoryMethodName!.isNotEmpty) {
      // If a factory method is specified, use it in the registration code
      return '''
          ServiceLocator.I.registerFactory<${factory.className}>(
            (serviceLocator, namedArgs) => ${factory.className}.${factory.factoryMethodName}(
              $allArgs),
              $interfaces,
              $name,
              $key,
              $environment,
          );
        '''
          .trim();
    } else {
      // If no factory method is specified, use the constructor with resolved dependencies and named arguments
      return '''
          ServiceLocator.I.registerFactory<${factory.className}>(
            (serviceLocator, namedArgs) => ${factory.className}(
              $allArgs),
              $interfaces,
              $name,
              $key,
              $environment,
          );
        '''
          .trim();
    }
  }

  static String generateLazyRegistration(LazyData lazyData) {
    // Resolve dependencies for the constructor parameters
    final dependencies =
        lazyData.dependencies.map((d) => "ServiceLocator.I.resolve(), ").join();

    final interfaces = lazyData.interfaces.isNotEmpty
        ? "interfaces: {${lazyData.interfaces.map((i) => i.className).join(', ')}}"
        : "interfaces: null";

    final name =
        lazyData.name != null ? "name: '${lazyData.name}'" : 'name: null';
    final key = lazyData.key != null ? "key: ${lazyData.key}" : 'key: null';
    final environment = lazyData.environment != null
        ? "environment: '${lazyData.environment}'"
        : 'environment: null';

    return '''
        ServiceLocator.I.registerLazy<${lazyData.className}>(
          Lazy<${lazyData.className}>(factory: () => ${lazyData.className}(${dependencies.isNotEmpty ? dependencies : ''}),),
          $interfaces,
          $name,
          $key,
          $environment,
        );''';
  }
}
