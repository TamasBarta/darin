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
    final scope = Scope(
      (scope) => scope
        ..factory<Iface>((scope) => Impl(scope.get()))
        ..factory<IDep>((p0) => Dep()),
    );

    Iface iface = scope.get<Iface>();
    iface.useDep();
  });

  test('scope dolgok', () {
    final scope = Scope((scope) => scope
      ..scope<IDep>(
        (scope) => scope
          ..factory<Iface>(
            (scope) => Impl(scope.get()),
          ),
      ));

    IDep dep = Dep();
    final newScope = scope.scope(dep);

    newScope.get<Iface>().useDep();
  });

  test('concat multiple scopes', () {
    final scope1 =
        Scope((scope) => scope..factory<IDep>((scope) => Dep()));
    final scope2 = Scope(
        (scope) => scope..factory<Iface>((scope) => Impl(scope.get())));

    final combinedScope1 = Scope.fromScopes(
      [
        scope1,
        scope2,
      ],
    );
    final combinedScope2 = Scope.fromScopes(
      [
        scope1,
        scope2,
      ],
    );

    combinedScope1.get<Iface>().useDep();
    combinedScope2.get<Iface>().useDep();
  });

  test('wrong scope usage', () {
    final depScope = Scope(
      (scope) => scope
        ..factory<IDep>((scope) => Dep())
        ..scope(
          (scope) => scope
            ..factory<Iface>(
              (scope) => Impl(scope.get()),
            ),
        ),
    );

    expect(() => depScope.get<Iface>(), throwsException);
  });

  test('scopeProvided', () {
    final scope = Scope(
      (scope) => scope
        ..factory<IDep>((_) => Dep())
        ..scope<IDep>(
          (scope) => scope..factory<Iface>((scope) => Impl(scope.get())),
        ),
    );

    final newScope = scope.scopeProvided<IDep>();

    final dep = newScope.get<IDep>();
    final depAgain = newScope.get<IDep>();

    expect(dep, depAgain);

    final impl = newScope.get<Iface>();
    final impl2 = newScope.get<Iface>();

    expect(impl, isNot(impl2));
  });

  group("providers", () {
    test("simpleProvider", () {
      var counter1 = 0;
      var counter2 = 0;
      final scope = Scope(
        (scope) => scope
          ..scoped(
            (scope) {
              counter1++;
              return "The String 1";
            },
            qualifier: 1,
          )
          ..factory(
            (scope) {
              counter2++;
              return "The String 2";
            },
            qualifier: 2,
          ),
      );
      final String Function() provider1 = scope.getProvider(qualifier: 1);
      final String Function() provider2 = scope.getProvider(qualifier: 2);

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

    test("scope", () {
      var counter = 0;

      final scope = Scope((scope) => scope
        ..scope<IDep>(
          (scope) {
            counter++;
            return scope
              ..factory<Iface>(
                (scope) => Impl(scope.get()),
              );
          },
        ));

      IDep dep = Dep();
      final newScope = scope.scopeProvider(dep);

      expect(counter, 0);

      newScope().get<Iface>().useDep();

      expect(counter, 1);
    });

    test("scopeProvided", () {
      var counter = 0;
      final scope = Scope(
        (scope) => scope
          ..factory<IDep>((_) => Dep())
          ..scope<IDep>(
            (scope) {
              counter++;
              return scope..factory<Iface>((scope) => Impl(scope.get()));
            },
          ),
      );

      var scopeProviderProvided = scope.scopeProviderProvided<IDep>();
      expect(counter, 0);

      final newScope = scopeProviderProvided();
      expect(counter, 1);

      final dep = newScope.get<IDep>();
      final depAgain = newScope.get<IDep>();

      expect(dep, depAgain);

      final impl = newScope.get<Iface>();
      final impl2 = newScope.get<Iface>();

      expect(impl, isNot(impl2));
    });
  });

  group("multibindings", () {
    test('multibinding', () {
      final scope = Scope(
        (scope) => scope
          ..intoMap<String, int>((scope) => {"foo": 1})
          ..intoMap<String, int>((scope) => {"bar": 2})
          ..intoSet<String>((scope) => {"foo"})
          ..intoSet<String>((scope) => {"bar"}),
      );

      expect(scope.getMap<Map<String, int>>(), {"foo": 1, "bar": 2});
      expect(scope.getSet<Set<String>>(), ["foo", "bar"]);
    });

    test('multibinding scopes', () {
      final scope = Scope(
        (scope) => scope
          ..scope<String>(
            (scope) => scope
              ..intoSet<String>((scope) => {"foo"})
              ..intoSet<String>((scope) => {"bar"})
              ..intoMap<String, int>((scope) => {"foo": 1})
              ..intoMap<String, int>((scope) => {"bar": 2}),
          ),
      );

      expect(
        scope.scope("yeah").getMap<Map<String, int>>(),
        {"foo": 1, "bar": 2},
      );
      expect(() => scope.getSet<Set<String>>(), throwsException);
    });

    test('multibinding but with inference', () {
      final scope = Scope(
        (scope) => scope
          ..intoMap((scope) => {"foo": 1})
          ..intoMap((scope) => {"bar": 2})
          ..intoSet((scope) => {"foo"})
          ..intoSet((scope) => {"bar"}),
      );

      Map<String, int> map = scope.getMap();
      Set<String> set = scope.getSet();

      expect(map, {"foo": 1, "bar": 2});
      expect(set, ["foo", "bar"]);
    });

    group("combine", () {
      test("map", () {
        final scope1 = Scope(
          (scope) => scope..intoMap((scope) => {"foo": "oof"}),
        );
        final scope2 = Scope(
          (scope) => scope..intoMap((scope) => {"bar": "rab"}),
        );
        final scope = Scope.fromScopes([scope1, scope2]);

        expect(
            scope.getMap<Map<String, String>>(), {"foo": "oof", "bar": "rab"});
      });

      test("set", () {
        final scope1 = Scope(
          (scope) => scope..intoSet((scope) => {"foo", "oof"}),
        );
        final scope2 = Scope(
          (scope) => scope..intoSet((scope) => {"bar", "rab"}),
        );
        final scope = Scope.fromScopes([scope1, scope2]);

        expect(scope.getSet<Set<String>>(), {"foo", "oof", "bar", "rab"});
      });
    });
  });
}
