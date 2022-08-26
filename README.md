# rules_rust_cargo_universe_hashbrown

A sample repository for bazelbuild/rules_rust#1527.

### How to build

```
bazel build //...
```

### How to update dependencies

```
bazel run //third_party:crates_vendor -- --repin
```
