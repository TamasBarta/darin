import 'package:darin/darin.dart';
import 'package:darin/src/dependency_handle.dart';
import 'package:test/test.dart';

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

  test('concat multiple modules', () {
    final module1 =
        Module((module) => module..factory<IDep>((module) => Dep()));
    final module2 = Module(
        (module) => module..factory<Iface>((module) => Impl(module.get())));

    final combinedModule1 = Module.fromModules(
      [
        module1,
        module2,
      ],
    );
    final combinedModule2 = Module.fromModules(
      [
        module1,
        module2,
      ],
    );

    combinedModule1.get<Iface>().useDep();
    combinedModule2.get<Iface>().useDep();
  });

  test('wrong scope usage', () {
    final depModule = Module(
      (module) => module
        ..factory<IDep>((module) => Dep())
        ..scope(
          (module) => module
            ..factory<Iface>(
              (module) => Impl(module.get()),
            ),
        ),
    );

    expect(() => depModule.get<Iface>(), throwsException);
  });
}
