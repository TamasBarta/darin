import 'dart:math';

class Location {
  final String name;

  Location(this.name);
}

class Greeter {
  final NameProvider _nameProvider;
  final Location Function() _locationProvider;

  Greeter(this._nameProvider, this._locationProvider);

  String getGreeting() =>
      "Hello ${_nameProvider.name}, from ${_locationProvider().name}!";
}

abstract class NameProvider {
  String get name;
}

class RandomNameProvider implements NameProvider {
  final String _name = ["World", "Woorld", "Wooorld"].random();
  @override
  String get name => _name;
}

abstract class GreetingPrinter {
  printGreeting();
}

class ConsoleGreetingPrinter implements GreetingPrinter {
  final Greeter _greeter;

  ConsoleGreetingPrinter(this._greeter);

  @override
  printGreeting() {
    print(_greeter.getGreeting());
  }
}

extension RandomItem<T> on List<T> {
  static final Random _random = Random();
  T random() => this[_random.nextInt(length)];
}
