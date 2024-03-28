import '../models/registrations.dart';

class CodeGenerationHelper {
  static String generateSingletonRegistration(SingletonData instance) {
    // Check if a factory method is provided for singleton creation
    if (instance.factoryMethodName != null &&
        instance.factoryMethodName!.isNotEmpty) {
      return generateSingletonRegistrationWithFunction(instance);
    } else {
      return generateSingletonRegistrationWithInstance(instance);
    }
  }

  static String generateSingletonRegistrationWithInstance(
      SingletonData instance) {
    String instanceCreation;

    // Instantiate the class directly, potentially with resolved dependencies
    String dependenciesResolution = _getDependencies(instance);

    instanceCreation = '${instance.className}($dependenciesResolution)';

    // Format additional registration parameters
    final interfaces = _getInterfaces(instance);
    final name = _getName(instance);
    final key = _getKey(instance);
    final environment = _getEnvironment(instance);

    // Construct the registration code for the singleton
    return '''
    ServiceLocator.I.registerSingleton<${instance.className}>(
        $instanceCreation,
        $interfaces,
        $name,
        $key,
        $environment,
    );
    ''';
  }

  static String generateSingletonRegistrationWithFunction(
      SingletonData instance) {
    // Ensure a factory method name is provided
    if (instance.factoryMethodName == null ||
        instance.factoryMethodName!.isEmpty) {
      throw Exception(
          'Factory method name must be provided for singleton function registration.');
    }

    // Resolve dependencies for the factory method
    final dependencies = _getDependencies(instance);

    // Resolve named arguments for the factory method
    final namedArgs = _getNamedArgs(instance);

    // Construct the function call to the factory method with resolved dependencies and named arguments
    String functionCall =
        '${instance.className}.${instance.factoryMethodName!}($dependencies${namedArgs.isNotEmpty ? ', ' : ''}$namedArgs)';

    // Format additional registration parameters
    final interfaces = _getInterfaces(instance);
    final name = _getName(instance);
    final key = _getKey(instance);
    final environment = _getEnvironment(instance);

    // Construct the registration code using a factory function
    return '''
    ServiceLocator.I.registerSingletonFactory<${instance.className}>(
        (serviceLocator) => $functionCall,
        $interfaces,
        $name,
        $key,
        $environment,
    );
    ''';
  }

  static String _getDependencies(TypeRegistration typeRegistration) {
    return typeRegistration.dependencies
        .map((dep) => "ServiceLocator.I.resolve<$dep>(),")
        .join();
  }

  static String _getNamedArgs(TypeRegistration typeRegistration) {
    if (typeRegistration is SingletonData) {
      return typeRegistration.namedArgs.entries
          .map((e) => "${e.key}: namedArgs['${e.key}'],")
          .join();
    } else if (typeRegistration is TransientData) {
      return typeRegistration.namedArgs.entries
          .map((e) => "${e.key}: namedArgs['${e.key}'] as ${e.value},")
          .join();
    } else {
      throw Exception('Unknown type registration');
    }
  }

  static String _getInterfaces(TypeRegistration typeRegistration) {
    return typeRegistration.interfaces.isNotEmpty
        ? "interfaces: {${typeRegistration.interfaces.map((i) => i.className).join(', ')}}"
        : "interfaces: null";
  }

  static String _getName(TypeRegistration typeRegistration) {
    return typeRegistration.name != null
        ? "name: '${typeRegistration.name}'"
        : 'name: null';
  }

  static String _getKey(TypeRegistration typeRegistration) {
    return typeRegistration.key != null
        ? "key: ${typeRegistration.key}"
        : 'key: null';
  }

  static String _getEnvironment(TypeRegistration typeRegistration) {
    return typeRegistration.environment != null
        ? "environment: '${typeRegistration.environment}'"
        : 'environment: null';
  }

  static String generateTransientRegistration(TransientData factory) {
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
          ServiceLocator.I.registerTransient<${factory.className}>(
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
          ServiceLocator.I.registerTransient<${factory.className}>(
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
