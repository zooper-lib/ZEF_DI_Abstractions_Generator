import 'package:zef_di_abstractions/zef_di_abstractions.dart';
import 'package:zef_di_inglue/zef_di_inglue.dart';

import 'dependency_registration.g.dart';
import 'test_files/services.dart';

void main(List<String> arguments) {
  ServiceLocatorBuilder().withAdapter(InglueServiceLocatorAdapter()).build();

  registerDependencies();

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

  final allServices =
      ServiceLocator.instance.resolveAll<AbstractService>(namedArgs: {
    'anyDouble': 10.0,
    'someValue': 5.0,
  });
  for (var service in allServices) {
    print('Got service: $service');
  }
}
