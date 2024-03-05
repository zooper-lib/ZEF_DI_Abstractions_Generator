import 'package:example/test_files/service_a.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

import 'abstract_service.dart';

@RegisterFactory()
class ServiceD implements AbstractService {
  final ServiceA serviceA;
  final double anyDouble;

  ServiceD(
    this.serviceA, {
    this.anyDouble = 0.0,
  });

  @override
  void doSomething() {
    print('ServiceD.doSomething');
  }

  @RegisterFactoryMethod()
  static ServiceD create(
    ServiceA serviceA, {
    double anyDouble = 0.0,
  }) {
    return ServiceD(
      serviceA,
      anyDouble: anyDouble,
    );
  }
}
