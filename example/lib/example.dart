import 'package:zef_di_abstractions/zef_di_abstractions.dart';
import 'package:zef_di_inglue/zef_di_inglue.dart';

import 'service_locator.g.dart';
import 'test_files/abstract_service.dart';
import 'test_files/service_a.dart';
import 'test_files/service_b.dart';
import 'test_files/service_c.dart';
import 'test_files/service_d.dart';

void main(List<String> arguments) {
  ServiceLocatorBuilder().withAdapter(InglueServiceLocatorAdapter()).build();

  registerGeneratedDependencies();

  final serviceA = ServiceLocator.instance.resolve<ServiceA>();
  serviceA.doSomething();

  final serviceB = ServiceLocator.instance.resolve<ServiceB>();
  serviceB.doSomething();

  final serviceC = ServiceLocator.instance.resolve<ServiceC>(namedArgs: {
    'someValue': 5.0,
    'anyDouble': 10.0,
  });
  serviceC.doSomething();

  final serviceD = ServiceLocator.instance.resolve<ServiceD>(namedArgs: {
    'anyDouble': 10.0,
  });
  serviceD.doSomething();

  final allServices = ServiceLocator.instance.resolveAll<AbstractService>();
  for (var service in allServices) {
    print('Got service: $service');
  }
}
