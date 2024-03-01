import 'package:example/test_files/service_a.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

@RegisterInstance()
class ServiceB {
  final ServiceA serviceA;

  ServiceB(this.serviceA);

  void doSomething() {
    serviceA.doSomething();

    print('ServiceB.doSomething');
  }
}
