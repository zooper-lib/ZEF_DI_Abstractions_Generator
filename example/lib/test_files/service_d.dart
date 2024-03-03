import 'package:example/test_files/service_a.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

@RegisterFactory()
class ServiceD {
  final ServiceA serviceA;

  ServiceD(this.serviceA);

  void doSomething() {
    serviceA.doSomething();

    print('ServiceD: doing something');
  }

  @RegisterFactoryMethod()
  static ServiceD create(ServiceA serviceA) {
    return ServiceD(serviceA);
  }
}
