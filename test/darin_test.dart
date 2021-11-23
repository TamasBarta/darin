import 'package:test/test.dart';

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
  doStuff() {}
}

void main() {
  test('hash stuff', () {
    const dh1 = DependencyHandle(IDep, null);
    const dh2 = DependencyHandle(IDep, null);

    final map = {dh1: "Hi"};

    expect(map[dh2], "Hi");
  });
  test('try getting a service', () {
    final module = Module(
      (module) => module
        ..factory<Iface>((module) => Impl(module.get()))
        ..factory<IDep>((p0) => Dep()),
    );

    Iface iface = module.get<Iface>();
    iface.useDep();
  });
  test('scope dolgok', () {
    final module = Module((module) => module
      ..scope<IDep>(
        (module) => module
          ..factory<Iface>(
            (module) => Impl(module.get()),
          ),
      ));

    IDep dep = Dep();
    final scope = module.scope(dep);

    scope.get<Iface>().useDep();
  });
}
