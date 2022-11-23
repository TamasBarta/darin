import 'scope.dart';

abstract class Provider<T> {
  Type type;
  T Function(Scope scope) factory;
  dynamic qualifier;

  Provider(this.factory, this.qualifier) : type = T;

  T provide(Scope scope);
}

class ScopedProvider<T> extends Provider<T> {
  ScopedProvider(T Function(Scope scope) factory, dynamic qualifier)
      : super(factory, qualifier);

  T? _instance;

  @override
  T provide(Scope scope) => _instance ??= factory(scope);
}

class FactoryProvider<T> extends Provider {
  FactoryProvider(T Function(Scope scope) factory, dynamic qualifier)
      : super(factory, qualifier);

  @override
  provide(Scope scope) => factory(scope);
}
