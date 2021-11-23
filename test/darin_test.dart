import 'package:flutter_test/flutter_test.dart';

import 'package:darin/darin.dart';

abstract class Iface {
  useDep();
}

class Impl implements Iface {
  final IDep _dep;

  @override
  useDep() => _dep.doStuff();

  Impl(this._dep);
}

abstract class IDep {
  doStuff() {}
}

class Dep implements IDep {
  @override
  doStuff() => throw UnimplementedError();
}

void main() {
  test('adds one to input values', () {
    final module = Module(
      (module) => module
        ..factory<Iface>((module) => Impl(module.get()))
        ..factory<IDep>((p0) => Dep()),
    );

    Iface iface = module.get<Iface>();
    iface.useDep();
  });
}
