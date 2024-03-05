import 'package:example/test_files/service_a.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

@RegisterFactory()
class ServiceD {
  final ServiceA serviceA;
  final double anyDouble;

  ServiceD(
    this.serviceA, {
    this.anyDouble = 0.0,
  });

  void doSomething() {
    serviceA.doSomething();

    print('ServiceD: doing something');
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
