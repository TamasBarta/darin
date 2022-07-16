import 'dependency_handle.dart';
import 'providers.dart';

class Scope {
  final Map<DependencyHandle, Provider> _providers = {};
  final Map<DependencyHandle, Set<ScopedProvider>> _multibindingProviders = {};
  final Scope? _parentScope;

  Scope._withParent(this._parentScope);

  Scope.fromScopes(List<Scope> scopes) : _parentScope = null {
    for (var element in scopes) {
      _providers.addAll(element._providers);
      element._multibindingProviders.forEach((key, value) {
        var set = _multibindingProviders[key];
        set ??= value;
        set.addAll(value);
        _multibindingProviders[key] = set;
      });
    }
  }

  Scope(Function(ScopeBuilder) builder) : _parentScope = null {
    builder(ScopeBuilder._(this));
  }

  T get<T>({dynamic qualifier}) {
    Scope? scope = this;
    Provider? provider;
    final handle = DependencyHandle(T, qualifier);
    while (scope != null) {
      provider = scope._providers[handle];
      if (provider != null) break;
      scope = scope._parentScope;
    }
    if (provider == null) {
      throw Exception(
          "The type $T with the qualifier $qualifier doesn't have any provider in the current scope.");
    }
    return provider.provide(this);
  }

  T Function() getProvider<T>({dynamic qualifier}) =>
      () => get<T>(qualifier: qualifier);

  Scope scope<S>(S owner) {
    var scope = get<Scope>(qualifier: S);
    ScopeBuilder._(scope).scoped<S>((scope) => owner);
    return scope;
  }

  Scope scopeProvided<S>({dynamic qualifier}) {
    var newScope = get<Scope>(qualifier: S);
    var owner = newScope.get<S>(qualifier: qualifier);
    ScopeBuilder._(newScope).scoped((scope) {
      return owner;
    });
    return newScope;
  }

  Scope Function() scopeProvider<S>(S owner) => () => scope<S>(owner);

  Scope Function() scopeProviderProvided<S>({dynamic qualifier}) =>
      () => scopeProvided<S>(qualifier: qualifier);

  Scope override(List<Scope> scopes) => Scope.fromScopes([this] + scopes);

  T getMap<T extends Map>({dynamic qualifier}) {
    Scope? scope = this;
    final providers = <Provider<T>, Scope>{};
    final handle = DependencyHandle(T, qualifier);
    while (scope != null) {
      final providerSet = scope._multibindingProviders[handle];
      if (providerSet != null && providerSet is Set<Provider<T>>) {
        providers.addEntries(
          providerSet.cast<Provider<T>>().map((e) => MapEntry(e, scope!)),
        );
      }
      scope = scope._parentScope;
    }
    if (providers.isEmpty) {
      throw Exception(
          "The map multibinding of $T with the qualifier $qualifier doesn't have any provider in the current scope.");
    }
    final providedMap = providers
        .map((provider, scope) {
          return MapEntry(provider, provider.provide(scope));
        })
        .values
        .reduce((value, element) {
          value.addAll(element);
          return value;
        });
    return providedMap;
  }

  T getSet<T extends Set>({dynamic qualifier}) {
    Scope? scope = this;
    final providers = <Provider<T>, Scope>{};
    final handle = DependencyHandle(T, qualifier);
    while (scope != null) {
      final providerSet = scope._multibindingProviders[handle];
      if (providerSet != null && providerSet is Set<Provider<T>>) {
        providers.addEntries(
          providerSet.cast<Provider<T>>().map((e) => MapEntry(e, scope!)),
        );
      }
      scope = scope._parentScope;
    }
    if (providers.isEmpty) {
      throw Exception(
          "The map multibinding of $T with the qualifier $qualifier doesn't have any provider in the current scope.");
    }
    final providedSet = providers
        .map((provider, scope) {
          return MapEntry(provider, provider.provide(scope));
        })
        .values
        .reduce((value, element) {
          value.addAll(element);
          return value;
        });
    return providedSet;
  }

  debug() {
    Scope? scope = this;
    while (scope != null) {
      print("SCOPE\n=============================");
      print("Bindings:");
      scope._providers.forEach((key, value) {
        print("${value is FactoryProvider ? 'factory' : 'scoped'} $key");
      });
      print("Multibindings:");
      scope._multibindingProviders.forEach((key, value) {
        print("${value is FactoryProvider ? 'factory' : 'scoped'} $key");
      });
      if (_parentScope != null) print("");
      scope = scope._parentScope;
    }
  }
}

class ScopeBuilder {
  final Scope _scope;

  ScopeBuilder._(this._scope);

  factory<T>(T Function(Scope) provider, {dynamic qualifier}) {
    _scope._providers[DependencyHandle(T, qualifier)] =
        FactoryProvider(provider, qualifier);
  }

  scoped<T>(T Function(Scope) provider, {dynamic qualifier}) {
    _scope._providers[DependencyHandle(T, qualifier)] =
        ScopedProvider(provider, qualifier);
  }

  scope<T>(Function(ScopeBuilder) scopeFactory) {
    factory((scope) {
      var childScope = Scope._withParent(_scope);
      scopeFactory(ScopeBuilder._(childScope));
      return childScope;
    }, qualifier: T);
  }

  intoMap<K, V>(Map<K, V> Function(Scope) provider, {dynamic qualifier}) {
    _intoMultibinding(provider, qualifier: qualifier);
  }

  intoSet<T>(Set<T> Function(Scope) provider, {dynamic qualifier}) {
    _intoMultibinding(provider, qualifier: qualifier);
  }

  _intoMultibinding<T>(T Function(Scope) provider, {dynamic qualifier}) {
    var set = _scope._multibindingProviders[DependencyHandle(T, qualifier)];
    set ??= <ScopedProvider<T>>{};
    set.add(ScopedProvider<T>(provider, qualifier));
    _scope._multibindingProviders[DependencyHandle(T, qualifier)] = set;
  }
}
