import 'services.dart';

class ModuleServiceA implements AbstractService {
  @override
  void doSomething() {
    print('ModuleServiceA');
  }
}

class ModuleServiceB {
  final ModuleServiceA serviceA;

  ModuleServiceB(this.serviceA);

  void doSomething() {
    print('ModuleServiceB');
  }
}

class ModuleServiceC {
  final ModuleServiceA serviceA;
  final ModuleServiceB serviceB;

  ModuleServiceC.create(
    this.serviceA,
    this.serviceB,
  );

  void doSomething() {
    print('ModuleServiceC');
  }
}

class ModuleServiceD {
  final ModuleServiceA serviceA;
  final ModuleServiceB serviceB;
  final ModuleServiceC serviceC;

  ModuleServiceD(
    this.serviceA,
    this.serviceB,
    this.serviceC,
  );

  void doSomething() {
    print('ModuleServiceD');
  }
}
