import 'dependency_handle.dart';
import 'providers.dart';

class Module {
  final Map<DependencyHandle, Provider> _providers = {};
  final Map<DependencyHandle, Set<ScopedProvider>> _multibindingProviders = {};
  final Module? _parentModule;

  Module._withParent(this._parentModule);

  Module.fromModules(List<Module> modules) : _parentModule = null {
    for (var element in modules) {
      _providers.addAll(element._providers);
      element._multibindingProviders.forEach((key, value) {
        var set = _multibindingProviders[key];
        set ??= value;
        set.addAll(value);
        _multibindingProviders[key] = set;
      });
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

  Module scopeProvided<S>({dynamic qualifier}) {
    var newScope = get<Module>(qualifier: S);
    var owner = newScope.get<S>(qualifier: qualifier);
    ModuleBuilder._(newScope).scoped((module) {
      return owner;
    });
    return newScope;
  }

  Module override(List<Module> modules) => Module.fromModules([this] + modules);

  T getMap<T extends Map>({dynamic qualifier}) {
    Module? module = this;
    final providers = <Provider<T>, Module>{};
    final handle = DependencyHandle(T, qualifier);
    while (module != null) {
      final providerSet = module._multibindingProviders[handle];
      if (providerSet != null && providerSet is Set<Provider<T>>) {
        providers.addEntries(
          providerSet.cast<Provider<T>>().map((e) => MapEntry(e, module!)),
        );
      }
      module = module._parentModule;
    }
    if (providers.isEmpty) {
      throw Exception(
          "The map multibinding of $T with the qualifier $qualifier doesn't have any provider in the current scope.");
    }
    final providedMap = providers
        .map((provider, module) {
          return MapEntry(provider, provider.provide(module));
        })
        .values
        .reduce((value, element) {
          value.addAll(element);
          return value;
        });
    return providedMap;
  }

  T getSet<T extends Set>({dynamic qualifier}) {
    Module? module = this;
    final providers = <Provider<T>, Module>{};
    final handle = DependencyHandle(T, qualifier);
    while (module != null) {
      final providerSet = module._multibindingProviders[handle];
      if (providerSet != null && providerSet is Set<Provider<T>>) {
        providers.addEntries(
          providerSet.cast<Provider<T>>().map((e) => MapEntry(e, module!)),
        );
      }
      module = module._parentModule;
    }
    if (providers.isEmpty) {
      throw Exception(
          "The map multibinding of $T with the qualifier $qualifier doesn't have any provider in the current scope.");
    }
    final providedSet = providers
        .map((provider, module) {
          return MapEntry(provider, provider.provide(module));
        })
        .values
        .reduce((value, element) {
          value.addAll(element);
          return value;
        });
    return providedSet;
  }
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

  intoMap<K, V>(Map<K, V> Function(Module) provider, {dynamic qualifier}) {
    _intoMultibinding(provider, qualifier: qualifier);
  }

  intoSet<T>(Set<T> Function(Module) provider, {dynamic qualifier}) {
    _intoMultibinding(provider, qualifier: qualifier);
  }

  _intoMultibinding<T>(T Function(Module) provider, {dynamic qualifier}) {
    var set = _module._multibindingProviders[DependencyHandle(T, qualifier)];
    set ??= <ScopedProvider<T>>{};
    set.add(ScopedProvider<T>(provider, qualifier));
    _module._multibindingProviders[DependencyHandle(T, qualifier)] = set;
  }
}
