// GENERATED CODE - DO NOT MODIFY BY HAND
// ******************************************************************************

import 'package:zef_di_abstractions/zef_di_abstractions.dart';
import 'package:example/test_files/service_a.dart';
import 'package:example/test_files/service_b.dart';
import 'package:example/test_files/service_c.dart';
import 'package:example/test_files/service_d.dart';

void registerGeneratedDependencies() {
  ServiceLocator.I.registerInstance<ServiceA>(ServiceA());

  ServiceLocator.I.registerInstance<ServiceB>(
      ServiceB(ServiceLocator.I.resolve<ServiceA>()));

  ServiceLocator.I.registerFactory<ServiceD>((serviceLocator, namedArgs) =>
      ServiceD.create(ServiceLocator.I.resolve<ServiceA>()));

  ServiceLocator.I.registerInstance<ServiceC>(
    ServiceC(
      ServiceLocator.I.resolve<ServiceA>(),
      ServiceLocator.I.resolve<ServiceB>(),
      ServiceLocator.I.resolve<ServiceD>(),
    ),
  );
}
