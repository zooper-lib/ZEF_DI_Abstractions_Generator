// GENERATED CODE - DO NOT MODIFY BY HAND
// ******************************************************************************

// ignore_for_file: implementation_imports, depend_on_referenced_packages, unused_import

import 'package:example/test_files/singleton_services.dart';
import 'package:example/test_files/module_services.dart';
import 'package:example/test_files/lazy_services.dart';
import 'package:example/test_files/transient_services.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';
import 'package:zef_helpers_lazy/zef_helpers_lazy.dart';

void registerDependencies() {
  ServiceLocator.I.registerSingleton<SingletonNoDependencies>(
    SingletonNoDependencies(),
    interfaces: {SingletonService},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerSingletonFactory<SingletonWithFactory>(
    (serviceLocator) => SingletonWithFactory.create(),
    interfaces: {SingletonService},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerSingleton<SingletonWithDependencies>(
    SingletonWithDependencies(
      ServiceLocator.I.resolve<SingletonNoDependencies>(),
    ),
    interfaces: {SingletonService},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I
      .registerSingletonFactory<SingletonWithFactoryWithDependencies>(
    (serviceLocator) => SingletonWithFactoryWithDependencies.create(
      ServiceLocator.I.resolve<SingletonNoDependencies>(),
    ),
    interfaces: {SingletonService},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerSingleton<ModuleNoDependencies>(
    ModuleNoDependencies(),
    interfaces: {SingletonService},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerSingletonFactory<ModuleWithFactory>(
    (serviceLocator) => ModuleWithFactory.create(),
    interfaces: null,
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerLazy<LazyNoDependencies>(
    Lazy<LazyNoDependencies>(
      factory: () => LazyNoDependencies(),
    ),
    interfaces: {LazyServices},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerLazy<LazyWithFactoryNoDependencies>(
    Lazy<LazyWithFactoryNoDependencies>(
        factory: () => LazyWithFactoryNoDependencies.create()),
    interfaces: {LazyServices},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerLazy<LazyWithDependencies>(
    Lazy<LazyWithDependencies>(
      factory: () => LazyWithDependencies(
        ServiceLocator.I.resolve<LazyNoDependencies>(),
      ),
    ),
    interfaces: {LazyServices},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerLazy<LazyWithFactoryWithDependencies>(
    Lazy<LazyWithFactoryWithDependencies>(
        factory: () => LazyWithFactoryWithDependencies.create()),
    interfaces: {LazyServices},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerTransient<TransientNoDependencies>(
    (serviceLocator, namedArgs) => TransientNoDependencies(),
    interfaces: {TransientService},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerTransient<TransientWithFactory>(
    (serviceLocator, namedArgs) => TransientWithFactory.create(),
    interfaces: {TransientService},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerTransient<TransientWithDependencies>(
    (serviceLocator, namedArgs) =>
        TransientWithDependencies(serviceLocator.resolve(namedArgs: namedArgs)),
    interfaces: {TransientService},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerTransient<TransientWithFactoryWithDependencies>(
    (serviceLocator, namedArgs) => TransientWithFactoryWithDependencies.create(
        serviceLocator.resolve(namedArgs: namedArgs)),
    interfaces: {TransientService},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerTransient<TransientWithNamedArgs>(
    (serviceLocator, namedArgs) => TransientWithNamedArgs(
      someValue: namedArgs['someValue'] as double,
    ),
    interfaces: {TransientService},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerTransient<TransientWithFactoryWithNamedArgs>(
    (serviceLocator, namedArgs) => TransientWithFactoryWithNamedArgs.create(
      someValue: namedArgs['someValue'] as double,
    ),
    interfaces: {TransientService},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerTransient<TransientWithDependencyWithNamedArgs>(
    (serviceLocator, namedArgs) => TransientWithDependencyWithNamedArgs(
      serviceLocator.resolve(namedArgs: namedArgs),
      someValue: namedArgs['someValue'] as double,
    ),
    interfaces: {TransientService},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I
      .registerTransient<TransientWithFactoryWithDependencyWithNamedArgs>(
    (serviceLocator, namedArgs) =>
        TransientWithFactoryWithDependencyWithNamedArgs.create(
      serviceLocator.resolve(namedArgs: namedArgs),
      someValue: namedArgs['someValue'] as double,
    ),
    interfaces: {TransientService},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerTransient<ModuleWithNamedArgs>(
    (serviceLocator, namedArgs) => ModuleWithNamedArgs(
      someValue: namedArgs['someValue'] as double,
    ),
    interfaces: null,
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerTransient<ModuleWithDependency>(
    (serviceLocator, namedArgs) =>
        ModuleWithDependency(serviceLocator.resolve(namedArgs: namedArgs)),
    interfaces: null,
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerLazy<ModuleWithFactoryWithDependencies>(
    Lazy<ModuleWithFactoryWithDependencies>(
        factory: () => ModuleWithFactoryWithDependencies.create(
              ServiceLocator.I.resolve<ModuleNoDependencies>(),
              ServiceLocator.I.resolve<ModuleWithDependency>(),
            )),
    interfaces: null,
    name: null,
    key: null,
    environment: null,
  );
}
