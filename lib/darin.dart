library darin;

class Module {
  final Map<DependencyHandle, Provider> _providers = {};
  final Module? _parentModule;

  Module._withParent(this._parentModule);

  Module(Function(ModuleBuilder) builder) : _parentModule = null {
    builder(ModuleBuilder._(this));
  }

  T get<T>({dynamic qualifier}) {
    Module? module = this;
    Provider? provider;
    final handle = DependencyHandle(T, qualifier);
    while (module != null) {
      provider = module._providers[handle];
      if (provider != null) break;
      module = module._parentModule;
    }
    if (provider == null) {
      throw Exception(
          "The type $T with the qualifier $qualifier doesn't have any provider in the current scope.");
    }
    return provider.provide(this);
  }

  Module scope<S>(S owner) {
    var module = get<Module>(qualifier: S);
    ModuleBuilder._(module).scoped<S>((module) => owner);
    return module;
  }
}

class DependencyHandle {
  final Type type;
  final dynamic qualifier;

  const DependencyHandle(this.type, this.qualifier);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DependencyHandle &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          qualifier == other.qualifier;

  @override
  int get hashCode => Object.hash(type, qualifier);

  @override
  String toString() => "[type: $type, qualifier: $qualifier]";
}

class ModuleBuilder {
  final Module _module;

  ModuleBuilder._(this._module);

  factory<T>(T Function(Module) provider, {dynamic qualifier}) {
    _module._providers[DependencyHandle(T, qualifier)] =
        FactoryProvider(provider, qualifier);
  }

  scoped<T>(T Function(Module) provider, {dynamic qualifier}) {
    _module._providers[DependencyHandle(T, qualifier)] =
        ScopedProvider(provider, qualifier);
  }

  scope<T>(Function(ModuleBuilder) scopeFactory) {
    factory((module) {
      var childModule = Module._withParent(_module);
      scopeFactory(ModuleBuilder._(childModule));
      return childModule;
    }, qualifier: T);
  }
}

abstract class Provider<T> {
  Type type;
  T Function(Module) factory;
  dynamic qualifier;

  Provider(this.factory, dynamic this.qualifier) : type = T;

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
