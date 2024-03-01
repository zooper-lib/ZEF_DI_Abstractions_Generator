import 'package:zef_di_abstractions/zef_di_abstractions.dart';

@RegisterInstance()
class ServiceA {
  void doSomething() {
    print('ServiceA.doSomething');
  }
}
