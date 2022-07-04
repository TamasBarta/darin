[![Dart](https://github.com/TamasBarta/darin/actions/workflows/dart.yml/badge.svg?branch=main)](https://github.com/TamasBarta/darin/actions/workflows/dart.yml)

Dependency Injection oversimplified. Inspired by Koin, with focus on scopes.

## Features

- Define your dependencies in a syntax as close to DSL as possible in Dart
- Use scopes to control the life-cycle of your objects (relying on the GC)
- Semi-automatic dependency resolution of dependencies
- NO MAGIC, all achieved by just regular Dart code, no unnecessary code generation

## Principles

- Use factory to get a new instance every time you request one
- Use scoped to get an instance that is persistent during the lifetime of your scope
- Scopes are super general, which means that if you want a singleton, you just create a scoped in a scope that you'll have around forever
- No built-in global/static container, if you want one, manage it for yourself 
- They live in a hierarchy, so first you create the widest scope, and as you create more and more below each other, they get narrower specific to a part of your application
- If your dependency is not available in your current scope, Darin will try to resolve it in all the parent scopes, that's how it is wider as you go up
- Your scopes are going to have owners. Owners are conceptually required to understand scopes are tied to their life-cycle. A scope should always be thrown away sooner than its owner, otherwise it's a memory leak

## Getting started

Import the package:

```yml
dependencies:
  darin:
```

## Usage

Create your scope like this:

```dart
final scope = Scope((scope) => scope
    ..factory<Interface1>((scope) => Implementation1())
    ..scoped<Interface2>((scope) => Implementation2(scope.get<Interface1>()))
    ..scope<Interface4>((scope) => scope
        ..factory<Interface4>((scope) => Implementation4(scope.get<Interface3>()))
        ..scoped<Interface5>((scope) => Implementation5(
            scope.get<Interface3>(),
            scope.get<Interface4>(),
        ))
    )
);
```

You can separate dependencies of your app's specific parts into multiple scopes (even across packages), and combine them in a single place:

```dart
final scope = Scope.fromScopes([
    scopeFromAPackage(),
    scopeFromBPackage(),
    scopeFromCPackage(),
]);
```

Use this `scope` as your dependency injection container. You can use it as a service locator, but I would suggest avoiding that, and define all your classes' providers in your scopes and sub-scopes, and just get a root object, and let Darin take care of resolving dependencies. If you go this route, don't forget to utilize provider support, or creating sub-scopes.

To get your dependencies:

```dart
final MyDep = scope.get<MyDep>();
```

To get narrower scopes:

```dart
// Owner will be `existingObject`, and will be available scoped in
// the sub-scope
final subscope = scope.scope<MyDep>(existingObject);

// or

// Owner of the scope will be provided by `scope`, and will be
// available as scoped in the sub-scope
final subscope = scope.scopeProvided(MyDep);
```

## Roadmap

- [x] Basic injection with scope support
- [x] Flutter integration via `InheritedWidget`
- [x] Set/Map support
- [x] Get the providers themselves similarly to getting the dependencies
- [ ] Parameters for factories

## Additional information

For integration with Flutter, see [Darin Flutter](https://github.com/TamasBarta/darin_flutter).

## For Koin users

Koin is designed for you to be able to get your dependency injection container anywhere in the application, where you don't have a reference to it. My guess would be that this is done this way, so you can use `val myDep by inject<MyDep>()` in your Android Activities, where you don't have any reference you could utilize to pass the context/scope down there, so a static accessor is required. This is not the case in Flutter, because in Flutter you actually control how your screens are created, and what you do have in your `BuildContexts`. For this reason I didn't include anything static that in turn would allow you to rely on a global reference. There are static functions for following Flutter patterns (think of `SomethingFluttery.of(BuildContext)`), but those rely on a `BuildContext`, so you don't use any global reference even behind the curtains. This is for a good reason, because you could always have parallel scopes set up for different reasons, and they wouldn't overwrite each other with a `Darin.start()` or something similar as in Koin.
