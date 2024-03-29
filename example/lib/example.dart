import 'package:example/test_files/lazy_services.dart';
import 'package:example/test_files/transient_services.dart';
import 'package:zef_di_abstractions/zef_di_abstractions.dart';
import 'package:zef_di_inglue/zef_di_inglue.dart';

import 'dependency_registration.g.dart';
import 'test_files/singleton_services.dart';

void main(List<String> arguments) {
  ServiceLocatorBuilder().withAdapter(InglueServiceLocatorAdapter()).build();

  registerDependencies();

  resolveSingletons();
  resolveTransients();
  resolveLazies();
}

void resolveSingletons() {
  final singletonNoDependencies =
      ServiceLocator.instance.resolve<SingletonNoDependencies>();
  singletonNoDependencies.doSomething();

  final singletonWithFactory =
      ServiceLocator.instance.resolve<SingletonWithFactory>();
  singletonWithFactory.doSomething();

  final singletonWithDependencies =
      ServiceLocator.instance.resolve<SingletonWithDependencies>();
  singletonWithDependencies.doSomething();

  final singletonWithFactoryWithDependencies =
      ServiceLocator.instance.resolve<SingletonWithFactoryWithDependencies>();
  singletonWithFactoryWithDependencies.doSomething();
}

void resolveTransients() {
  final transientNoDependencies =
      ServiceLocator.instance.resolve<TransientNoDependencies>();
  transientNoDependencies.doSomething();

  final transientWithFactory =
      ServiceLocator.instance.resolve<TransientWithFactory>();
  transientWithFactory.doSomething();

  final transientWithDependencies =
      ServiceLocator.instance.resolve<TransientWithDependencies>();
  transientWithDependencies.doSomething();

  final transientWithFactoryWithDependencies =
      ServiceLocator.instance.resolve<TransientWithFactoryWithDependencies>();
  transientWithFactoryWithDependencies.doSomething();

  final transientWithNamedArgs =
      ServiceLocator.instance.resolve<TransientWithNamedArgs>(namedArgs: {
    'someValue': 5.0,
  });
  transientWithNamedArgs.doSomething();

  final transientWithFactoryWithNamedArgs = ServiceLocator.instance
      .resolve<TransientWithFactoryWithNamedArgs>(namedArgs: {
    'someValue': 5.0,
  });
  transientWithFactoryWithNamedArgs.doSomething();

  final transientWithFactoryWithDependencyWithNamedArgs = ServiceLocator
      .instance
      .resolve<TransientWithFactoryWithDependencyWithNamedArgs>(namedArgs: {
    'someValue': 5.0,
  });
  transientWithFactoryWithDependencyWithNamedArgs.doSomething();
}

void resolveLazies() {
  final lazyNoDependencies =
      ServiceLocator.instance.resolve<LazyNoDependencies>();
  lazyNoDependencies.doSomething();

  final lazyWithFactoryNoDependencies =
      ServiceLocator.instance.resolve<LazyWithFactoryNoDependencies>();
  lazyWithFactoryNoDependencies.doSomething();

  final lazyWithDependencies =
      ServiceLocator.instance.resolve<LazyWithDependencies>();
  lazyWithDependencies.doSomething();

  final lazyWithFactoryWithDependencies =
      ServiceLocator.instance.resolve<LazyWithFactoryWithDependencies>();
  lazyWithFactoryWithDependencies.doSomething();
}
