part of darin;

class Module {
  final Map<DependencyHandle, Provider> _providers = {};
  final Module? _parentModule;

  Module._withParent(this._parentModule);

  Module.fromModules(List<Module> modules) : _parentModule = null {
    for (var element in modules) {
      _providers.addAll(element._providers);
    }
  }

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

  Module override(List<Module> modules) => Module.fromModules([this] + modules);
}
