// ignore_for_file: unused_field

import 'package:example/test_files/service_a.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

import 'abstract_service.dart';

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
