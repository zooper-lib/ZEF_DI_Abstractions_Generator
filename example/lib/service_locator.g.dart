// GENERATED CODE - DO NOT MODIFY BY HAND
// ******************************************************************************

import 'package:zef_di_abstractions/zef_di_abstractions.dart';
import 'package:example/test_files/service_a.dart';
import 'package:example/test_files/abstract_service.dart';
import 'package:example/test_files/service_b.dart';
import 'package:example/test_files/service_c.dart';
import 'package:example/test_files/service_d.dart';

void registerGeneratedDependencies() {
  ServiceLocator.I.registerInstance<ServiceA>(
    ServiceA(),
    interfaces: [ServiceA, Object, AbstractService],
    name: 'foobla',
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerInstance<ServiceB>(
    ServiceB(ServiceLocator.I.resolve<ServiceA>()),
    interfaces: [ServiceB, Object, AbstractService],
    name: null,
    key: null,
    environment: null,
  );

  ServiceLocator.I.registerFactory<ServiceC>(
    (serviceLocator, namedArgs) => ServiceC(
        serviceLocator.resolve<ServiceA>(namedArgs: namedArgs),
        serviceLocator.resolve<ServiceB>(namedArgs: namedArgs),
        serviceLocator.resolve<ServiceD>(namedArgs: namedArgs)),
    interfaces: [ServiceC, Object, AbstractService],
    name: 'blafoo',
    key: null,
    environment: 'test',
  );

  ServiceLocator.I.registerFactory<ServiceD>(
    (serviceLocator, namedArgs) => ServiceD.create(
        serviceLocator.resolve<ServiceA>(namedArgs: namedArgs),
        anyDouble: namedArgs['anyDouble'] as double),
    interfaces: [ServiceD, Object, AbstractService],
    name: null,
    key: null,
    environment: null,
  );
}
