import 'package:darin/darin.dart';

import '_dependencies.dart';

/// This example is an enterprise hello world (meaning absolutely overcomplicated)
/// to demonstrate dependencies, and how to define the DI config for them.
/// It shows how to create scopes, scope your dependencies, and use providers.
///
/// I don't want to overexplain the code, but some explanation helps understanding it:
/// - This hello world "visits locations", and greets "from there" (meaning printed
///   lines have a location in them).
/// - Each visit is in its own scope, so when you use the location provider, you
///   automatically get the one belonging to that visit.
/// - Only to demonstrate how to scope dependencies, [RandomNameProvider] is
///   scoped (on the topmost scope, so technically it's a singleton), so remembers
///   what was randomized at first usage for the whole lifecycle of the app.
void main() {
  Scope mainScope = buildMainScope();

  var locations = [Location("GitHub"), Location("pub.dev")];
  for (var location in locations) {
    var scope = mainScope.scope(location);
    scope.get<GreetingPrinter>().printGreeting();
  }
}

// Below is all the Darin specific code

/// Builds the main scope in this example. This is considered a singleton,
/// as the application's logic keeps it for the whole lifecycle of the application.
Scope buildMainScope() {
  return Scope(
    (builder) {
      return builder
        ..scoped<NameProvider>((scope) => RandomNameProvider())
        ..factory<GreetingPrinter>(
          (scope) => ConsoleGreetingPrinter(scope.get()),
        )
        ..scope<Location>(
          (builder) => builder
            ..factory(
              (scope) => Greeter(scope.get(), scope.getProvider()),
            ),
        );
    },
  );
}

