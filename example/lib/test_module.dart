import 'package:example/test_files/module_services.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';

@DependencyModule()
abstract class TestModule {
  @RegisterSingleton()
  ModuleNoDependencies get moduleNoDependencies;

  @RegisterTransient()
  ModuleWithDependency moduleWithDependency(
          ModuleNoDependencies moduleServiceA) =>
      ModuleWithDependency(moduleServiceA);

  @RegisterSingleton()
  ModuleWithFactory get moduleServiceC;

  @RegisterLazy()
  ModuleWithFactoryWithDependencies moduleWithFactoryWithDependencies(
    ModuleNoDependencies moduleServiceA,
    ModuleWithDependency moduleServiceB,
  ) =>
      ModuleWithFactoryWithDependencies.create(
        moduleServiceA,
        moduleServiceB,
      );

  @RegisterTransient()
  ModuleWithNamedArgs get moduleServiceD;
}
