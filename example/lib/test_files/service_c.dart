import 'package:example/test_files/service_d.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

import 'abstract_service.dart';
import 'service_a.dart';
import 'service_b.dart';

@RegisterFactory(name: 'blafoo', environment: 'test')
class ServiceC implements AbstractService {
  final ServiceA serviceA;
  final ServiceB serviceB;
  final ServiceD serviceD;

  ServiceC(
    this.serviceA,
    this.serviceB,
    this.serviceD,
  );

  @override
  void doSomething() {
    print('ServiceC.doSomething');
  }
}
