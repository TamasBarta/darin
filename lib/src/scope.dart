import 'dependency_handle.dart';
import 'providers.dart';

/// Represents a scope, that you can use to retrieve what it holds.
class Scope {
  final Map<DependencyHandle, Provider> _providers = {};
  final Map<DependencyHandle, Set<ScopedProvider>> _multibindingProviders = {};
  final Scope? _parentScope;

  Scope._withParent(this._parentScope);

  /// Returns a new [Scope] that has all the providers from all the scopes
  /// in the [scopes] list.
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

  /// Main way to define a scope with a [ScopeBuilder] that allows you
  /// to define the providers for the dependencies.
  Scope(Function(ScopeBuilder builder) builder) : _parentScope = null {
    builder(ScopeBuilder._(this));
  }

  /// Retrieves [T] from the scope with its provider. Throws if a provider
  /// is not available for [T].
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

  /// Returns a function that can later be used to obtain [T] with its
  /// provider in the scope.
  T Function() getProvider<T>({dynamic qualifier}) =>
      () => get<T>(qualifier: qualifier);

  /// Creates a new scope that provides [owner] as "scoped".
  ///
  /// See concepts to understand what's the difference between "scoped"
  /// and "factory".
  Scope scope<S>(S owner) {
    var scope = get<Scope>(qualifier: S);
    ScopeBuilder._(scope).scoped<S>((scope) => owner);
    return scope;
  }

  /// Creates a new scope that provides a dependency with the type [S]
  /// which is automatically created using a provider from the current
  /// scope.
  Scope scopeProvided<S>({dynamic qualifier}) {
    var newScope = get<Scope>(qualifier: S);
    var owner = newScope.get<S>(qualifier: qualifier);
    ScopeBuilder._(newScope).scoped((scope) {
      return owner;
    });
    return newScope;
  }

  /// Returns a function that can later be used to obtain a new scope
  /// that provides [owner] as "scoped".
  ///
  /// See concepts to understand what's the difference between "scoped"
  /// and "factory".
  Scope Function() scopeProvider<S>(S owner) => () => scope<S>(owner);

  /// Returns a function that can later be used to obtain a new scope
  /// that provides a dependency with the type [S] which is automatically
  /// created at the time of the new scope's creation using a provider
  /// from the current scope.
  Scope Function() scopeProviderProvided<S>({dynamic qualifier}) =>
      () => scopeProvided<S>(qualifier: qualifier);

  /// Uses all the providers of the scopes from [scopes] to override
  /// providers in the current scope.
  Scope override(List<Scope> scopes) => Scope.fromScopes([this] + scopes);

  /// Combines all providers in the map multibinding of [T] into a single
  /// map and returns it.
  ///
  /// If multiple providers are present with the same key, they override
  /// each other in order, meaning the last one wins.
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

  /// Combines all providers in the set multibinding of [T] into a single
  /// set and returns it.
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
          "The set multibinding of $T with the qualifier $qualifier doesn't have any provider in the current scope.");
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

  /// Prints a text representation of the scope to the console.
  ///
  /// Can be useful for debugging if you're not sure that your scope
  /// was built/combined correctly.
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

/// Allows you to define the providers for a scope to be created once it
/// is needed in.
///
/// Think of the difference between [ScopeBuilder] and [Scope] as you can
/// use [Scope] to retrieve the dependencies, and you can use [ScopeBuilder]
/// to define how they are created.
class ScopeBuilder {
  final Scope _scope;

  ScopeBuilder._(this._scope);

  /// Adds a provider that is run every time the dependency is requested.
  ///
  /// If your [provider] doesn't reuse objects, a factory returns a new
  /// object every time, but that also allows these objects to be cleaned
  /// up by the garbage collector, as they are not cached in the scope.
  factory<T>(T Function(Scope scope) provider, {dynamic qualifier}) {
    _scope._providers[DependencyHandle(T, qualifier)] =
        FactoryProvider(provider, qualifier);
  }

  /// Adds a provider that is run once per scope instance, when the
  /// dependency is requested the first time.
  ///
  /// This prevents the garbage collector to clean this dependency up
  /// as long as the scope is also in the memory.
  scoped<T>(T Function(Scope scope) provider, {dynamic qualifier}) {
    _scope._providers[DependencyHandle(T, qualifier)] =
        ScopedProvider(provider, qualifier);
  }

  /// Lends you another [ScopeBuilder] where you can define the dependencies'
  /// providers valid in a scope of a [T].
  scope<T>(Function(ScopeBuilder builder) scopeFactory) {
    factory((scope) {
      var childScope = Scope._withParent(_scope);
      scopeFactory(ScopeBuilder._(childScope));
      return childScope;
    }, qualifier: T);
  }

  /// Appends a provider to the map multibinding of [T].
  ///
  /// Duplicate keys don't throw, they simply override each other, and
  /// the last one wins.
  intoMap<K, V>(Map<K, V> Function(Scope scope) provider, {dynamic qualifier}) {
    _intoMultibinding(provider, qualifier: qualifier);
  }

  /// Appends a provider to the set multibinding of [T].
  intoSet<T>(Set<T> Function(Scope scope) provider, {dynamic qualifier}) {
    _intoMultibinding(provider, qualifier: qualifier);
  }

  _intoMultibinding<T>(T Function(Scope scope) provider, {dynamic qualifier}) {
    var set = _scope._multibindingProviders[DependencyHandle(T, qualifier)];
    set ??= <ScopedProvider<T>>{};
    set.add(ScopedProvider<T>(provider, qualifier));
    _scope._multibindingProviders[DependencyHandle(T, qualifier)] = set;
  }
}
