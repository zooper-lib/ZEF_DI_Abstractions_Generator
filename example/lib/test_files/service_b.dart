import 'package:example/test_files/abstract_service.dart';
import 'package:example/test_files/service_a.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

@RegisterLazy()
class ServiceB implements AbstractService {
  final ServiceA serviceA;

  ServiceB(this.serviceA);

  @override
  void doSomething() {
    print('ServiceB.doSomething');
  }
}
