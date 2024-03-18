import 'package:example/test_files/module_services.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

@DependencyModule()
abstract class TestModule {
  @RegisterInstance(environment: 'test2')
  ModuleServiceA get moduleServiceA;

  @RegisterFactory()
  ModuleServiceB moduleServiceB(ModuleServiceA moduleServiceA) =>
      ModuleServiceB(moduleServiceA);

  @RegisterLazy(name: 'TestLazy')
  ModuleServiceC moduleServiceC(
    ModuleServiceA moduleServiceA,
    ModuleServiceB moduleServiceB,
  ) =>
      ModuleServiceC(
        moduleServiceA,
        moduleServiceB,
      );

  @RegisterInstance()
  ModuleServiceD get moduleServiceD;
}
