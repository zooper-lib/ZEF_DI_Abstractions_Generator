// GENERATED CODE - DO NOT MODIFY BY HAND
// ******************************************************************************

import 'package:example/test_files/services.dart';
import 'package:example/test_files/module_services.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';
import 'package:zef_helpers_lazy/zef_helpers_lazy.dart';

void registerDependencies() {
  ServiceLocator.I.registerInstance<ServiceA>(
    ServiceA(),
    interfaces: {AbstractService},
    name: 'foobla',
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerInstance<ModuleServiceA>(
    ModuleServiceA(),
    interfaces: {AbstractService},
    name: null,
    key: null,
    environment: 'test2',
  );

  ServiceLocator.I.registerFactory<ModuleServiceB>(
    (serviceLocator, namedArgs) =>
        ModuleServiceB(serviceLocator.resolve(namedArgs: namedArgs)),
    interfaces: null,
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerLazy<ModuleServiceC>(
    Lazy<ModuleServiceC>(
      factory: () => ModuleServiceC(
        ServiceLocator.I.resolve(),
        ServiceLocator.I.resolve(),
      ),
    ),
    interfaces: null,
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerInstance<ModuleServiceD>(
    ModuleServiceD(
      ServiceLocator.I.resolve(),
      ServiceLocator.I.resolve(),
      ServiceLocator.I.resolve(),
    ),
    interfaces: null,
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerLazy<ServiceB>(
    Lazy<ServiceB>(
      factory: () => ServiceB(
        ServiceLocator.I.resolve(),
      ),
    ),
    interfaces: {AbstractService},
    name: 'ServiceB',
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerFactory<ServiceC>(
    (serviceLocator, namedArgs) => ServiceC(
        serviceLocator.resolve(namedArgs: namedArgs),
        serviceLocator.resolve(namedArgs: namedArgs),
        serviceLocator.resolve(namedArgs: namedArgs)),
    interfaces: {AbstractService},
    name: 'blafoo',
    key: null,
    environment: 'test',
  );

  ServiceLocator.I.registerFactory<ServiceD>(
    (serviceLocator, namedArgs) => ServiceD.create(
      serviceLocator.resolve(namedArgs: namedArgs),
      anyDouble: namedArgs['anyDouble'] as double,
    ),
    interfaces: {AbstractService},
    name: null,
    key: null,
    environment: null,
  );
}
