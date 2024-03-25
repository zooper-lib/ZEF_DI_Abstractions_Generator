import 'package:example/test_files/module_services.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

//@DependencyModule()
abstract class TestModule {
  @RegisterSingleton(environment: 'test2')
  ModuleServiceA get moduleServiceA;

  @RegisterTransient()
  ModuleServiceB moduleServiceB(ModuleServiceA moduleServiceA) =>
      ModuleServiceB(moduleServiceA);

  @RegisterLazy(name: 'TestLazy')
  ModuleServiceC moduleServiceC(
    ModuleServiceA moduleServiceA,
    ModuleServiceB moduleServiceB,
  ) =>
      ModuleServiceC.create(
        moduleServiceA,
        moduleServiceB,
      );

  @RegisterTransient()
  ModuleServiceD get moduleServiceD;
}
