// GENERATED CODE - DO NOT MODIFY BY HAND
// ******************************************************************************

import 'package:example/test_files/service_a.dart';
import 'package:example/test_files/abstract_service.dart';
import 'package:example/test_files/service_b.dart';
import 'package:example/test_files/service_c.dart';
import 'package:example/test_files/service_d.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';
import 'package:zef_helpers_lazy/zef_helpers_lazy.dart';

void registerDependencies() {
  ServiceLocator.I.registerInstance<ServiceA>(
    ServiceA(),
    interfaces: {AbstractService, ServiceA},
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
    interfaces: {AbstractService, ServiceB},
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerFactory<ServiceC>(
    (serviceLocator, namedArgs) => ServiceC(
        serviceLocator.resolve(namedArgs: namedArgs),
        serviceLocator.resolve(namedArgs: namedArgs),
        serviceLocator.resolve(namedArgs: namedArgs)),
    interfaces: {AbstractService, ServiceC},
    name: 'blafoo',
    key: null,
    environment: 'test',
  );

  ServiceLocator.I.registerFactory<ServiceD>(
    (serviceLocator, namedArgs) => ServiceD.create(
      serviceLocator.resolve(namedArgs: namedArgs),
      anyDouble: namedArgs['anyDouble'] as double,
    ),
    interfaces: {AbstractService, ServiceD},
    name: null,
    key: null,
    environment: null,
  );
}
