import 'package:example/test_files/service_d.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

import 'service_a.dart';
import 'service_b.dart';

@RegisterInstance()
class ServiceC {
  final ServiceA serviceA;
  final ServiceB serviceB;
  final ServiceD serviceD;

  ServiceC(
    this.serviceA,
    this.serviceB,
    this.serviceD,
  );

  void doSomething() {
    serviceA.doSomething();
    serviceB.doSomething();
    serviceD.doSomething();
    print('ServiceC: doing something');
  }
}
