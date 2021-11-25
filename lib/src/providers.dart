import 'module.dart';

abstract class Provider<T> {
  Type type;
  T Function(Module) factory;
  dynamic qualifier;

  Provider(this.factory, this.qualifier) : type = T;

  T provide(Module module);
}

class ScopedProvider<T> extends Provider<T> {
  ScopedProvider(T Function(Module) factory, dynamic qualifier)
      : super(factory, qualifier);

  T? _instance;

  @override
  T provide(Module module) => _instance ??= factory(module);
}

class FactoryProvider<T> extends Provider {
  FactoryProvider(T Function(Module) factory, dynamic qualifier)
      : super(factory, qualifier);

  @override
  provide(Module module) => factory(module);
}
