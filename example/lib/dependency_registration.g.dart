// GENERATED CODE - DO NOT MODIFY BY HAND
// ******************************************************************************

// ignore_for_file: implementation_imports, depend_on_referenced_packages, unused_import

import 'package:example/test_files/services.dart';
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
      anyDouble: namedArgs['anyDouble'] as double,
    ),
    interfaces: {AbstractService},
    name: null,
    key: null,
    environment: null,
  );
}
