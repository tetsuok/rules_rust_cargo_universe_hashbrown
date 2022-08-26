###############################################################################
# @generated
# DO NOT MODIFY: This file is auto-generated by a crate_universe tool. To
# regenerate this file, run the following:
#
#     bazel run //third_party:crates_vendor
###############################################################################
"""
# `crates_repository` API

- [aliases](#aliases)
- [crate_deps](#crate_deps)
- [all_crate_deps](#all_crate_deps)
- [crate_repositories](#crate_repositories)

"""

load("@bazel_skylib//lib:selects.bzl", "selects")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

###############################################################################
# MACROS API
###############################################################################

# An identifier that represent common dependencies (unconditional).
_COMMON_CONDITION = ""

def _flatten_dependency_maps(all_dependency_maps):
    """Flatten a list of dependency maps into one dictionary.

    Dependency maps have the following structure:

    ```python
    DEPENDENCIES_MAP = {
        # The first key in the map is a Bazel package
        # name of the workspace this file is defined in.
        "workspace_member_package": {

            # Not all dependnecies are supported for all platforms.
            # the condition key is the condition required to be true
            # on the host platform.
            "condition": {

                # An alias to a crate target.     # The label of the crate target the
                # Aliases are only crate names.   # package name refers to.
                "package_name":                   "@full//:label",
            }
        }
    }
    ```

    Args:
        all_dependency_maps (list): A list of dicts as described above

    Returns:
        dict: A dictionary as described above
    """
    dependencies = {}

    for workspace_deps_map in all_dependency_maps:
        for pkg_name, conditional_deps_map in workspace_deps_map.items():
            if pkg_name not in dependencies:
                non_frozen_map = dict()
                for key, values in conditional_deps_map.items():
                    non_frozen_map.update({key: dict(values.items())})
                dependencies.setdefault(pkg_name, non_frozen_map)
                continue

            for condition, deps_map in conditional_deps_map.items():
                # If the condition has not been recorded, do so and continue
                if condition not in dependencies[pkg_name]:
                    dependencies[pkg_name].setdefault(condition, dict(deps_map.items()))
                    continue

                # Alert on any miss-matched dependencies
                inconsistent_entries = []
                for crate_name, crate_label in deps_map.items():
                    existing = dependencies[pkg_name][condition].get(crate_name)
                    if existing and existing != crate_label:
                        inconsistent_entries.append((crate_name, existing, crate_label))
                    dependencies[pkg_name][condition].update({crate_name: crate_label})

    return dependencies

def crate_deps(deps, package_name = None):
    """Finds the fully qualified label of the requested crates for the package where this macro is called.

    Args:
        deps (list): The desired list of crate targets.
        package_name (str, optional): The package name of the set of dependencies to look up.
            Defaults to `native.package_name()`.

    Returns:
        list: A list of labels to generated rust targets (str)
    """

    if not deps:
        return []

    if package_name == None:
        package_name = native.package_name()

    # Join both sets of dependencies
    dependencies = _flatten_dependency_maps([
        _NORMAL_DEPENDENCIES,
        _NORMAL_DEV_DEPENDENCIES,
        _PROC_MACRO_DEPENDENCIES,
        _PROC_MACRO_DEV_DEPENDENCIES,
        _BUILD_DEPENDENCIES,
        _BUILD_PROC_MACRO_DEPENDENCIES,
    ]).pop(package_name, {})

    # Combine all conditional packages so we can easily index over a flat list
    # TODO: Perhaps this should actually return select statements and maintain
    # the conditionals of the dependencies
    flat_deps = {}
    for deps_set in dependencies.values():
        for crate_name, crate_label in deps_set.items():
            flat_deps.update({crate_name: crate_label})

    missing_crates = []
    crate_targets = []
    for crate_target in deps:
        if crate_target not in flat_deps:
            missing_crates.append(crate_target)
        else:
            crate_targets.append(flat_deps[crate_target])

    if missing_crates:
        fail("Could not find crates `{}` among dependencies of `{}`. Available dependencies were `{}`".format(
            missing_crates,
            package_name,
            dependencies,
        ))

    return crate_targets

def all_crate_deps(
        normal = False,
        normal_dev = False,
        proc_macro = False,
        proc_macro_dev = False,
        build = False,
        build_proc_macro = False,
        package_name = None):
    """Finds the fully qualified label of all requested direct crate dependencies \
    for the package where this macro is called.

    If no parameters are set, all normal dependencies are returned. Setting any one flag will
    otherwise impact the contents of the returned list.

    Args:
        normal (bool, optional): If True, normal dependencies are included in the
            output list.
        normal_dev (bool, optional): If True, normla dev dependencies will be
            included in the output list..
        proc_macro (bool, optional): If True, proc_macro dependencies are included
            in the output list.
        proc_macro_dev (bool, optional): If True, dev proc_macro dependencies are
            included in the output list.
        build (bool, optional): If True, build dependencies are included
            in the output list.
        build_proc_macro (bool, optional): If True, build proc_macro dependencies are
            included in the output list.
        package_name (str, optional): The package name of the set of dependencies to look up.
            Defaults to `native.package_name()` when unset.

    Returns:
        list: A list of labels to generated rust targets (str)
    """

    if package_name == None:
        package_name = native.package_name()

    # Determine the relevant maps to use
    all_dependency_maps = []
    if normal:
        all_dependency_maps.append(_NORMAL_DEPENDENCIES)
    if normal_dev:
        all_dependency_maps.append(_NORMAL_DEV_DEPENDENCIES)
    if proc_macro:
        all_dependency_maps.append(_PROC_MACRO_DEPENDENCIES)
    if proc_macro_dev:
        all_dependency_maps.append(_PROC_MACRO_DEV_DEPENDENCIES)
    if build:
        all_dependency_maps.append(_BUILD_DEPENDENCIES)
    if build_proc_macro:
        all_dependency_maps.append(_BUILD_PROC_MACRO_DEPENDENCIES)

    # Default to always using normal dependencies
    if not all_dependency_maps:
        all_dependency_maps.append(_NORMAL_DEPENDENCIES)

    dependencies = _flatten_dependency_maps(all_dependency_maps).pop(package_name, None)

    if not dependencies:
        if dependencies == None:
            fail("Tried to get all_crate_deps for package " + package_name + " but that package had no Cargo.toml file")
        else:
            return []

    crate_deps = list(dependencies.pop(_COMMON_CONDITION, {}).values())
    for condition, deps in dependencies.items():
        crate_deps += selects.with_or({_CONDITIONS[condition]: deps.values()})

    return crate_deps

def aliases(
        normal = False,
        normal_dev = False,
        proc_macro = False,
        proc_macro_dev = False,
        build = False,
        build_proc_macro = False,
        package_name = None):
    """Produces a map of Crate alias names to their original label

    If no dependency kinds are specified, `normal` and `proc_macro` are used by default.
    Setting any one flag will otherwise determine the contents of the returned dict.

    Args:
        normal (bool, optional): If True, normal dependencies are included in the
            output list.
        normal_dev (bool, optional): If True, normla dev dependencies will be
            included in the output list..
        proc_macro (bool, optional): If True, proc_macro dependencies are included
            in the output list.
        proc_macro_dev (bool, optional): If True, dev proc_macro dependencies are
            included in the output list.
        build (bool, optional): If True, build dependencies are included
            in the output list.
        build_proc_macro (bool, optional): If True, build proc_macro dependencies are
            included in the output list.
        package_name (str, optional): The package name of the set of dependencies to look up.
            Defaults to `native.package_name()` when unset.

    Returns:
        dict: The aliases of all associated packages
    """
    if package_name == None:
        package_name = native.package_name()

    # Determine the relevant maps to use
    all_aliases_maps = []
    if normal:
        all_aliases_maps.append(_NORMAL_ALIASES)
    if normal_dev:
        all_aliases_maps.append(_NORMAL_DEV_ALIASES)
    if proc_macro:
        all_aliases_maps.append(_PROC_MACRO_ALIASES)
    if proc_macro_dev:
        all_aliases_maps.append(_PROC_MACRO_DEV_ALIASES)
    if build:
        all_aliases_maps.append(_BUILD_ALIASES)
    if build_proc_macro:
        all_aliases_maps.append(_BUILD_PROC_MACRO_ALIASES)

    # Default to always using normal aliases
    if not all_aliases_maps:
        all_aliases_maps.append(_NORMAL_ALIASES)
        all_aliases_maps.append(_PROC_MACRO_ALIASES)

    aliases = _flatten_dependency_maps(all_aliases_maps).pop(package_name, None)

    if not aliases:
        return dict()

    common_items = aliases.pop(_COMMON_CONDITION, {}).items()

    # If there are only common items in the dictionary, immediately return them
    if not len(aliases.keys()) == 1:
        return dict(common_items)

    # Build a single select statement where each conditional has accounted for the
    # common set of aliases.
    crate_aliases = {"//conditions:default": common_items}
    for condition, deps in aliases.items():
        condition_triples = _CONDITIONS[condition]
        if condition_triples in crate_aliases:
            crate_aliases[condition_triples].update(deps)
        else:
            crate_aliases.update({_CONDITIONS[condition]: dict(deps.items() + common_items)})

    return selects.with_or(crate_aliases)

###############################################################################
# WORKSPACE MEMBER DEPS AND ALIASES
###############################################################################

_NORMAL_DEPENDENCIES = {
    "": {
        _COMMON_CONDITION: {
            "ahash": "@crates_vendor__ahash-0.7.6//:ahash",
            "hashbrown": "@crates_vendor__hashbrown-0.12.3//:hashbrown",
        },
    },
}

_NORMAL_ALIASES = {
    "": {
        _COMMON_CONDITION: {
        },
    },
}

_NORMAL_DEV_DEPENDENCIES = {
    "": {
    },
}

_NORMAL_DEV_ALIASES = {
    "": {
    },
}

_PROC_MACRO_DEPENDENCIES = {
    "": {
    },
}

_PROC_MACRO_ALIASES = {
    "": {
    },
}

_PROC_MACRO_DEV_DEPENDENCIES = {
    "": {
    },
}

_PROC_MACRO_DEV_ALIASES = {
    "": {
    },
}

_BUILD_DEPENDENCIES = {
    "": {
    },
}

_BUILD_ALIASES = {
    "": {
    },
}

_BUILD_PROC_MACRO_DEPENDENCIES = {
    "": {
    },
}

_BUILD_PROC_MACRO_ALIASES = {
    "": {
    },
}

_CONDITIONS = {
    "cfg(any(target_os = \"linux\", target_os = \"android\", target_os = \"windows\", target_os = \"macos\", target_os = \"ios\", target_os = \"freebsd\", target_os = \"openbsd\", target_os = \"netbsd\", target_os = \"dragonfly\", target_os = \"solaris\", target_os = \"illumos\", target_os = \"fuchsia\", target_os = \"redox\", target_os = \"cloudabi\", target_os = \"haiku\", target_os = \"vxworks\", target_os = \"emscripten\", target_os = \"wasi\"))": ["x86_64-unknown-linux-gnu"],
    "cfg(not(all(target_arch = \"arm\", target_os = \"none\")))": ["x86_64-unknown-linux-gnu"],
    "cfg(target_os = \"wasi\")": [],
    "cfg(unix)": ["x86_64-unknown-linux-gnu"],
}

###############################################################################

def crate_repositories():
    """A macro for defining repositories for all generated crates"""
    maybe(
        http_archive,
        name = "crates_vendor__ahash-0.7.6",
        patch_args = [
            "-p1",
        ],
        patches = [
            "@com_github_tetsuok_rules_rust_cargo_universe_hashbrown//third_party:ahash.patch",
        ],
        sha256 = "fcb51a0695d8f838b1ee009b3fbf66bda078cd64590202a864a8f3e8c4315c47",
        type = "tar.gz",
        urls = ["https://crates.io/api/v1/crates/ahash/0.7.6/download"],
        strip_prefix = "ahash-0.7.6",
        build_file = Label("@com_github_tetsuok_rules_rust_cargo_universe_hashbrown//third_party/crates:BUILD.ahash-0.7.6.bazel"),
    )

    maybe(
        http_archive,
        name = "crates_vendor__cfg-if-1.0.0",
        sha256 = "baf1de4339761588bc0619e3cbc0120ee582ebb74b53b4efbf79117bd2da40fd",
        type = "tar.gz",
        urls = ["https://crates.io/api/v1/crates/cfg-if/1.0.0/download"],
        strip_prefix = "cfg-if-1.0.0",
        build_file = Label("@com_github_tetsuok_rules_rust_cargo_universe_hashbrown//third_party/crates:BUILD.cfg-if-1.0.0.bazel"),
    )

    maybe(
        http_archive,
        name = "crates_vendor__getrandom-0.2.7",
        sha256 = "4eb1a864a501629691edf6c15a593b7a51eebaa1e8468e9ddc623de7c9b58ec6",
        type = "tar.gz",
        urls = ["https://crates.io/api/v1/crates/getrandom/0.2.7/download"],
        strip_prefix = "getrandom-0.2.7",
        build_file = Label("@com_github_tetsuok_rules_rust_cargo_universe_hashbrown//third_party/crates:BUILD.getrandom-0.2.7.bazel"),
    )

    maybe(
        http_archive,
        name = "crates_vendor__hashbrown-0.12.3",
        sha256 = "8a9ee70c43aaf417c914396645a0fa852624801b24ebb7ae78fe8272889ac888",
        type = "tar.gz",
        urls = ["https://crates.io/api/v1/crates/hashbrown/0.12.3/download"],
        strip_prefix = "hashbrown-0.12.3",
        build_file = Label("@com_github_tetsuok_rules_rust_cargo_universe_hashbrown//third_party/crates:BUILD.hashbrown-0.12.3.bazel"),
    )

    maybe(
        http_archive,
        name = "crates_vendor__libc-0.2.132",
        sha256 = "8371e4e5341c3a96db127eb2465ac681ced4c433e01dd0e938adbef26ba93ba5",
        type = "tar.gz",
        urls = ["https://crates.io/api/v1/crates/libc/0.2.132/download"],
        strip_prefix = "libc-0.2.132",
        build_file = Label("@com_github_tetsuok_rules_rust_cargo_universe_hashbrown//third_party/crates:BUILD.libc-0.2.132.bazel"),
    )

    maybe(
        http_archive,
        name = "crates_vendor__once_cell-1.13.1",
        sha256 = "074864da206b4973b84eb91683020dbefd6a8c3f0f38e054d93954e891935e4e",
        type = "tar.gz",
        urls = ["https://crates.io/api/v1/crates/once_cell/1.13.1/download"],
        strip_prefix = "once_cell-1.13.1",
        build_file = Label("@com_github_tetsuok_rules_rust_cargo_universe_hashbrown//third_party/crates:BUILD.once_cell-1.13.1.bazel"),
    )

    maybe(
        http_archive,
        name = "crates_vendor__version_check-0.9.4",
        sha256 = "49874b5167b65d7193b8aba1567f5c7d93d001cafc34600cee003eda787e483f",
        type = "tar.gz",
        urls = ["https://crates.io/api/v1/crates/version_check/0.9.4/download"],
        strip_prefix = "version_check-0.9.4",
        build_file = Label("@com_github_tetsuok_rules_rust_cargo_universe_hashbrown//third_party/crates:BUILD.version_check-0.9.4.bazel"),
    )

    maybe(
        http_archive,
        name = "crates_vendor__wasi-0.11.0-wasi-snapshot-preview1",
        sha256 = "9c8d87e72b64a3b4db28d11ce29237c246188f4f51057d65a7eab63b7987e423",
        type = "tar.gz",
        urls = ["https://crates.io/api/v1/crates/wasi/0.11.0+wasi-snapshot-preview1/download"],
        strip_prefix = "wasi-0.11.0+wasi-snapshot-preview1",
        build_file = Label("@com_github_tetsuok_rules_rust_cargo_universe_hashbrown//third_party/crates:BUILD.wasi-0.11.0+wasi-snapshot-preview1.bazel"),
    )
