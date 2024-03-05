import 'package:example/test_files/abstract_service.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

@RegisterInstance(name: 'foobla')
class ServiceA implements AbstractService {
  @override
  void doSomething() {
    print('ServiceA.doSomething');
  }
}
