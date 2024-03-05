import 'package:zef_di_abstractions/zef_di_abstractions.dart';
import 'package:zef_di_inglue/zef_di_inglue.dart';

import 'service_locator.g.dart';
import 'test_files/service_c.dart';

void main(List<String> arguments) {
  ServiceLocatorBuilder().withAdapter(InglueServiceLocatorAdapter()).build();

  registerGeneratedDependencies();

  final serviceC = ServiceLocator.instance.resolve<ServiceC>(namedArgs: {
    'someValue': 5.0,
    'anyDouble': 10.0,
  });
  serviceC.doSomething();
}
