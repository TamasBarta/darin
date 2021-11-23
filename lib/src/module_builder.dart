part of darin;

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
