## 0.1.2

- Added API documentation
- Added example app to demonstrate basic usage

## 0.1.1

- Added names to anonymous function parameters (I expect the Dart language server to pick it up, and use it, when autocompletes the anonymous functions)

## 0.1.0

- Added `debug` on scopes to print all providers and parent scopes until top

BREAKING CHANGES:

- Renamed all module terminology to scope to eliminate confusion

## 0.0.3

Added support for injecting providers of scopes too.

## 0.0.2

Added support for provider injection (lazy dependencies).

## 0.0.1

Initial release with support for:

- Resolution based on providers
- Scopes
- Qualifiers
- Multibindings (set, map)
- Module concatenation
- Overriding providers on modules
