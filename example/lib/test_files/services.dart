// ignore_for_file: unused_field

import 'package:zef_di_abstractions/zef_di_abstractions.dart';

abstract class AbstractService {
  void doSomething();
}

@RegisterInstance(name: 'foobla')
class ServiceA implements AbstractService {
  @override
  void doSomething() {
    print('ServiceA.doSomething');
  }
}

@RegisterLazy(name: 'ServiceB')
class ServiceB implements AbstractService {
  final ServiceA serviceA;

  ServiceB(this.serviceA);

  @override
  void doSomething() {
    print('ServiceB.doSomething');
  }
}

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

@RegisterFactory()
class ServiceD implements AbstractService {
  final ServiceA _serviceA;
  final double _anyDouble;

  ServiceD(
    this._serviceA, {
    required double anyDouble,
  }) : _anyDouble = anyDouble;

  @override
  void doSomething() {
    print('ServiceD.doSomething');
  }

  @RegisterFactoryMethod()
  static ServiceD create(
    ServiceA serviceA, {
    required double anyDouble,
  }) {
    return ServiceD(
      serviceA,
      anyDouble: anyDouble,
    );
  }
}
