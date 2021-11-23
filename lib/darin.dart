library darin;

class Module {
  final Map<DependencyHandle, Provider> _providers = {};
  final Module? _parentModule;

  Module._withParent(this._parentModule);

  Module(Function(ModuleBuilder) builder) : _parentModule = null {
    builder(ModuleBuilder(this));
  }

  T get<T>() {
    Module? module = this;
    Provider? provider;
    while (module != null) {
      provider = module._providers[T];
      if (provider != null) break;
      module = module._parentModule;
    }
    if (provider == null) {
      throw Exception(
          "The type $T doesn't have any provider in the current scope.");
    }
    return provider.provide(this);
  }

  Module scope(String scopeName) {
    final provider = _providers[DependencyHandle(Module, scopeName)];
    if (provider == null) {
      throw Exception("The scope with the name $scopeName is not defined.");
    }
    return provider.provide(this);
  }
}

class DependencyHandle {
  Type type;
  String? name;

  DependencyHandle(this.type, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DependencyHandle &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          name == other.name;

  @override
  int get hashCode => type.hashCode ^ (name?.hashCode ?? 0);
}

class ModuleBuilder {
  final Module _module;

  ModuleBuilder(this._module);

  factory<T>(T Function(Module) provider, {String? name}) {
    _module._providers[DependencyHandle(T, name)] = FactoryProvider(provider);
  }

  scoped<T>(T Function(Module) provider, {String? name}) {
    _module._providers[DependencyHandle(T, name)] = ScopedProvider(provider);
  }

  scope<T>(String scopeName, T owner, Function(ModuleBuilder) scopeFactory) {
    factory((module) {
      var childModule = Module._withParent(_module);
      scopeFactory(ModuleBuilder(childModule));
      return childModule;
    }, name: scopeName);
  }
}

abstract class Provider<T> {
  Type type;
  T Function(Module) factory;

  Provider(this.factory) : type = T;

  T provide(Module module);
}

class ScopedProvider<T> extends Provider<T> {
  ScopedProvider(T Function(Module) factory) : super(factory);

  T? _instance;

  @override
  T provide(Module module) => _instance ??= factory(module);
}

class FactoryProvider extends Provider {
  FactoryProvider(Function(Module) factory) : super(factory);

  @override
  provide(Module module) => factory(module);
}
