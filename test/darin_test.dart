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

  test('scopeProvided', () {
    final module = Module(
      (module) => module
        ..factory<IDep>((_) => Dep())
        ..scope<IDep>(
          (module) => module..factory<Iface>((module) => Impl(module.get())),
        ),
    );

    final scope = module.scopeProvided<IDep>();

    final dep = scope.get<IDep>();
    final depAgain = scope.get<IDep>();

    expect(dep, depAgain);

    final impl = scope.get<Iface>();
    final impl2 = scope.get<Iface>();

    expect(impl, isNot(impl2));
  });

  group("providers", () {
    test("simpleProvider", () {
      var counter1 = 0;
      var counter2 = 0;
      final module = Module(
        (module) => module
          ..scoped(
            (module) {
              counter1++;
              return "The String 1";
            },
            qualifier: 1,
          )
          ..factory(
            (module) {
              counter2++;
              return "The String 2";
            },
            qualifier: 2,
          ),
      );
      final String Function() provider1 = module.getProvider(qualifier: 1);
      final String Function() provider2 = module.getProvider(qualifier: 2);

      expect(counter1, 0);
      expect(counter2, 0);

      expect(provider1(), "The String 1");
      expect(provider2(), "The String 2");

      expect(counter1, 1);
      expect(counter2, 1);

      expect(provider1(), "The String 1");
      expect(provider2(), "The String 2");

      expect(counter1, 1);
      expect(counter2, 2);
    });
  });

  group("multibindings", () {
    test('multibinding', () {
      final module = Module(
        (module) => module
          ..intoMap<String, int>((module) => {"foo": 1})
          ..intoMap<String, int>((module) => {"bar": 2})
          ..intoSet<String>((module) => {"foo"})
          ..intoSet<String>((module) => {"bar"}),
      );

      expect(module.getMap<Map<String, int>>(), {"foo": 1, "bar": 2});
      expect(module.getSet<Set<String>>(), ["foo", "bar"]);
    });

    test('multibinding scopes', () {
      final module = Module(
        (module) => module
          ..scope<String>(
            (module) => module
              ..intoSet<String>((module) => {"foo"})
              ..intoSet<String>((module) => {"bar"})
              ..intoMap<String, int>((module) => {"foo": 1})
              ..intoMap<String, int>((module) => {"bar": 2}),
          ),
      );

      expect(
        module.scope("yeah").getMap<Map<String, int>>(),
        {"foo": 1, "bar": 2},
      );
      expect(() => module.getSet<Set<String>>(), throwsException);
    });

    test('multibinding but with inference', () {
      final module = Module(
        (module) => module
          ..intoMap((module) => {"foo": 1})
          ..intoMap((module) => {"bar": 2})
          ..intoSet((module) => {"foo"})
          ..intoSet((module) => {"bar"}),
      );

      Map<String, int> map = module.getMap();
      Set<String> set = module.getSet();

      expect(map, {"foo": 1, "bar": 2});
      expect(set, ["foo", "bar"]);
    });

    group("combine", () {
      test("map", () {
        final module1 = Module(
          (module) => module..intoMap((module) => {"foo": "oof"}),
        );
        final module2 = Module(
          (module) => module..intoMap((module) => {"bar": "rab"}),
        );
        final module = Module.fromModules([module1, module2]);

        expect(
            module.getMap<Map<String, String>>(), {"foo": "oof", "bar": "rab"});
      });

      test("set", () {
        final module1 = Module(
          (module) => module..intoSet((module) => {"foo", "oof"}),
        );
        final module2 = Module(
          (module) => module..intoSet((module) => {"bar", "rab"}),
        );
        final module = Module.fromModules([module1, module2]);

        expect(module.getSet<Set<String>>(), {"foo", "oof", "bar", "rab"});
      });
    });
  });
}
