workspace(name = "com_github_tetsuok_rules_rust_cargo_universe_hashbrown")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_rust",
    sha256 = "6bfe75125e74155955d8a9854a8811365e6c0f3d33ed700bc17f39e32522c822",
    urls = [
        "https://github.com/bazelbuild/rules_rust/releases/download/0.9.0/rules_rust-v0.9.0.tar.gz",
    ],
)

load("@rules_rust//rust:repositories.bzl", "rules_rust_dependencies", "rust_register_toolchains")

rules_rust_dependencies()

rust_register_toolchains(
    edition = "2021",
    version = "1.63.0",
)

load("@rules_rust//crate_universe:repositories.bzl", "crate_universe_dependencies")

crate_universe_dependencies()

load("@rules_rust//crate_universe:defs.bzl", "crate", "crates_repository", "render_config")

# after changing:
#   CARGO_BAZEL_REPIN=1 bazel sync --only=crate_index
crates_repository(
    name = "crate_index",
    annotations = {
        "ahash": [crate.annotation(
            patch_args = ["-p1"],
            patches = ["@com_github_tetsuok_rules_rust_cargo_universe_hashbrown//:ahash.patch"],
            version = "=0.7.6",
        )],
    },
    cargo_lockfile = "//:Cargo.Bazel.lock",
    lockfile = "//:cargo-bazel-lock.json",
    packages = {
        "hashbrown": crate.spec(
            version = "0.12.3",
        ),
    },
    render_config = render_config(
        default_package_name = "",
    ),
    supported_platform_triples = ["x86_64-unknown-linux-gnu"],
)

load("@crate_index//:defs.bzl", "crate_repositories")

crate_repositories()
