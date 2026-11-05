cmake_minimum_required(VERSION 3.19)

set(REMOTE_REPO_URL "https://github.com/caelestia-dots/shell.git")

# A fork must not report upstream's identity. REMOTE_REPO_URL above points at
# caelestia-dots/shell, so a bare configure here baked in *upstream's* newest tag and
# *upstream's* HEAD -- `caelestia --version` then printed a revision that is not in this tree,
# which is the string a user pastes into a bug report. Prefer the local checkout, which
# describes what is actually being built and needs no network; fall back to the remote query
# only for a source tree with no .git, which is what that path was really for.
if(NOT DEFINED VERSION)
    execute_process(
        COMMAND git -C "${CMAKE_CURRENT_SOURCE_DIR}" describe --tags --abbrev=0
        OUTPUT_VARIABLE LOCAL_TAG
        RESULT_VARIABLE LOCAL_TAG_RESULT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )

    if(LOCAL_TAG_RESULT EQUAL 0 AND NOT "${LOCAL_TAG}" STREQUAL "")
        set(VERSION "${LOCAL_TAG}")
    endif()
endif()

if(NOT DEFINED VERSION)
    # Fetch the latest annotated or lightweight tag from the remote repo
    execute_process(
        COMMAND git ls-remote --tags --sort=-v:refname "${REMOTE_REPO_URL}"
        OUTPUT_VARIABLE REMOTE_TAGS_RAW
        RESULT_VARIABLE GIT_TAG_RESULT
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(NOT GIT_TAG_RESULT EQUAL 0 OR "${REMOTE_TAGS_RAW}" STREQUAL "")
        message(FATAL_ERROR "Failed to query tags from ${REMOTE_REPO_URL}")
    endif()

    # Extract the first ref tag name (strips commit hash and peels ^{})
    string(REGEX MATCH "refs/tags/([^\n\^\t ]+)" _MATCH "${REMOTE_TAGS_RAW}")
    set(VERSION "${CMAKE_MATCH_1}")

    if("${VERSION}" STREQUAL "")
        message(FATAL_ERROR "VERSION is not set and failed to parse from remote tags")
    endif()
endif()

if(NOT DEFINED GIT_REVISION)
    execute_process(
        COMMAND git -C "${CMAKE_CURRENT_SOURCE_DIR}" rev-parse HEAD
        OUTPUT_VARIABLE LOCAL_HEAD
        RESULT_VARIABLE LOCAL_HEAD_RESULT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )

    if(LOCAL_HEAD_RESULT EQUAL 0 AND NOT "${LOCAL_HEAD}" STREQUAL "")
        set(GIT_REVISION "${LOCAL_HEAD}")
    endif()
endif()

if(NOT DEFINED GIT_REVISION)
    # Fetch HEAD commit hash from the remote repo
    execute_process(
        COMMAND git ls-remote "${REMOTE_REPO_URL}" HEAD
        OUTPUT_VARIABLE REMOTE_HEAD_RAW
        RESULT_VARIABLE GIT_REV_RESULT
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(NOT GIT_REV_RESULT EQUAL 0 OR "${REMOTE_HEAD_RAW}" STREQUAL "")
        message(FATAL_ERROR "GIT_REVISION is not set and failed to get from remote repo")
    endif()

    # Extract the 40-character commit SHA
    string(REGEX MATCH "^([0-9a-fA-F]+)" GIT_REVISION "${REMOTE_HEAD_RAW}")
endif()

string(REGEX REPLACE "^v" "" VERSION "${VERSION}")

# `-DVERSION=` is *defined but empty*, so both detection blocks above are skipped and
# `project()` gets no value at all -- CMake warns "VERSION keyword not followed by a value"
# and PROJECT_VERSION ends up empty. That is not hypothetical: verify.sh and build.yml both
# pass `-DVERSION= -DGIT_REVISION=` on purpose, to keep the gate off the network and
# independent of how the tree is tagged, so every gate and CI build produced a binary whose
# `caelestia --version` printed two empty strings (extras/version.cpp prints both verbatim).
#
# Fill in placeholders rather than falling back to detection: falling back would reintroduce
# exactly the network dependency the empty values exist to avoid. A build that says 0.0.0 and
# "unknown" is honest about being an unversioned build; one that says nothing looks broken.
if("${VERSION}" STREQUAL "")
    set(AETHER_VERSION_WAS_UNSET TRUE)
    set(VERSION "0.0.0")
endif()
if("${GIT_REVISION}" STREQUAL "")
    set(GIT_REVISION "unknown")
endif()

# What the shell shows as its version. Semantic Versioning, with the build's distance from the
# last release tag as the pre-release counter:
#
#   2.6.0-dev.978+g8867aae        HEAD is 978 commits past v2.5.0
#   2.6.0-dev.978+g8867aae-dirty  ...and the working tree has uncommitted changes
#   2.5.0                         HEAD is exactly the release tag
#
# `dev.N` is the load-bearing part. SemVer ignores build metadata when ordering, so a bare
# `+<sha>` -- or the `r<sha>` this used to print -- can never be compared to another build,
# and a bare tag cannot say how far past it the build is. The distance and the tag come from
# `git describe --long`; the tag's minor number is bumped to name the release this build is
# heading for. Everything is read from the local repository, so the `-DVERSION=
# -DGIT_REVISION=` gate builds still need no network.
set(AETHER_DISPLAY_VERSION "${VERSION}")

execute_process(
    COMMAND git -C "${CMAKE_CURRENT_SOURCE_DIR}" describe --tags --long --always --abbrev=7 --dirty
    OUTPUT_VARIABLE AETHER_DESCRIBE
    RESULT_VARIABLE AETHER_DESCRIBE_RESULT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
)

if(AETHER_DESCRIBE_RESULT EQUAL 0 AND NOT "${AETHER_DESCRIBE}" STREQUAL "")
    if("${AETHER_DESCRIBE}" MATCHES "^v?([0-9]+)\\.([0-9]+)\\.([0-9]+)-([0-9]+)-g([0-9a-f]+)(-dirty)?$")
        set(AETHER_TAG_MAJOR "${CMAKE_MATCH_1}")
        set(AETHER_TAG_MINOR "${CMAKE_MATCH_2}")
        set(AETHER_TAG_PATCH "${CMAKE_MATCH_3}")
        set(AETHER_DISTANCE "${CMAKE_MATCH_4}")
        set(AETHER_SHORT_SHA "${CMAKE_MATCH_5}")
        set(AETHER_DIRTY "${CMAKE_MATCH_6}")

        if("${AETHER_DISTANCE}" STREQUAL "0" AND NOT AETHER_DIRTY)
            # HEAD *is* the tagged release, so there is nothing to qualify.
            set(AETHER_DISPLAY_VERSION "${AETHER_TAG_MAJOR}.${AETHER_TAG_MINOR}.${AETHER_TAG_PATCH}")
        else()
            math(EXPR AETHER_NEXT_MINOR "${AETHER_TAG_MINOR} + 1")
            set(AETHER_DISPLAY_VERSION
                "${AETHER_TAG_MAJOR}.${AETHER_NEXT_MINOR}.0-dev.${AETHER_DISTANCE}+g${AETHER_SHORT_SHA}${AETHER_DIRTY}")
        endif()
    elseif("${AETHER_DESCRIBE}" MATCHES "^([0-9a-f]+)(-dirty)?$")
        # No reachable tag, so `--always` returned the commit itself: a shallow clone or a
        # tagless export. The commit count stands in for the distance so the string still
        # orders sensibly; it is 1 in a depth-1 clone, which is the most that can be known.
        set(AETHER_SHORT_SHA "${CMAKE_MATCH_1}")
        set(AETHER_DIRTY "${CMAKE_MATCH_2}")

        execute_process(
            COMMAND git -C "${CMAKE_CURRENT_SOURCE_DIR}" rev-list --count HEAD
            OUTPUT_VARIABLE AETHER_COMMIT_COUNT
            RESULT_VARIABLE AETHER_COMMIT_COUNT_RESULT
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
        )

        if(NOT AETHER_COMMIT_COUNT_RESULT EQUAL 0 OR "${AETHER_COMMIT_COUNT}" STREQUAL "")
            set(AETHER_COMMIT_COUNT "0")
        endif()

        set(AETHER_DISPLAY_VERSION "0.0.0-dev.${AETHER_COMMIT_COUNT}+g${AETHER_SHORT_SHA}${AETHER_DIRTY}")
    endif()
endif()

project(aether-shell VERSION ${VERSION} LANGUAGES CXX)

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "/" CACHE PATH "Installation prefix" FORCE)
endif()

include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

set(DISTRIBUTOR "Unset" CACHE STRING "Distributor")
set(ENABLE_MODULES "extras;plugin;shell" CACHE STRING "Modules to build/install")
set(INSTALL_LIBDIR "${CMAKE_INSTALL_LIBDIR}/caelestia" CACHE STRING "Library install dir")
set(INSTALL_QMLDIR "${CMAKE_INSTALL_LIBDIR}/qt6/qml" CACHE STRING "QML install dir")
set(INSTALL_QTPLUGINDIR "${CMAKE_INSTALL_LIBDIR}/qt6/plugins" CACHE STRING "Qt plugin install dir")
set(INSTALL_QSCONFDIR "${CMAKE_INSTALL_SYSCONFDIR}/xdg/quickshell/caelestia" CACHE STRING "Quickshell config install dir")

add_compile_definitions(
    QT_NO_CAST_FROM_ASCII
    QT_NO_CAST_TO_ASCII
    QT_NO_CAST_FROM_BYTEARRAY
)

add_compile_options(
    -Wall -Wextra -Wpedantic -Wshadow -Wconversion
    -Wold-style-cast -Wnull-dereference -Wdouble-promotion
    -Wformat=2 -Wfloat-equal -Woverloaded-virtual
    -Wsign-conversion -Wredundant-decls -Wswitch
    -Wunreachable-code
)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-Wunused-lambda-capture -Wno-nonportable-include-path)
endif()

if("extras" IN_LIST ENABLE_MODULES)
    add_subdirectory(extras)
endif()

if("plugin" IN_LIST ENABLE_MODULES)
    add_subdirectory(plugin)
endif()

if("shell" IN_LIST ENABLE_MODULES)
    foreach(dir assets components daemons modules services utils)
        install(DIRECTORY ${dir} DESTINATION "${INSTALL_QSCONFDIR}")
    endforeach()

    # Only the command surface is needed at runtime; hybrid/tools and hybrid/docs are for
    # the checkout.
    install(DIRECTORY hybrid/bin hybrid/cli DESTINATION "${INSTALL_QSCONFDIR}/hybrid"
        PATTERN "__pycache__" EXCLUDE PATTERN "*.pyc" EXCLUDE)

    # install(DIRECTORY) does not carry the executable bit. The QML callers run this file
    # directly, so it has to stay executable.
    install(PROGRAMS hybrid/bin/aether DESTINATION "${INSTALL_QSCONFDIR}/hybrid/bin")

    # Runtime helpers (bt-agent, app-fonts, doctor, display-draft, wifi-connect,
    # startup-shell) are resolved through Quickshell.shellPath("scripts/..."), so an
    # installed shell without them fails every one of those features. A directory install
    # preserves the executable bits.
    install(DIRECTORY scripts DESTINATION "${INSTALL_QSCONFDIR}"
        PATTERN "__pycache__" EXCLUDE PATTERN "*.pyc" EXCLUDE)
    # wifi-connect.sh is executed directly (Nmcli.runWifiConnect), and a directory install
    # gives it 0644; PROGRAMS sets the executable bit back.
    install(PROGRAMS scripts/wifi-connect.sh scripts/askpass.sh DESTINATION "${INSTALL_QSCONFDIR}/scripts")

    install(PROGRAMS assets/wrap_term_launch.sh DESTINATION "${INSTALL_QSCONFDIR}/assets")

    file(READ shell.qml SHELL_QML)
    string(REPLACE "settings.watchFiles: true" "settings.watchFiles: false" SHELL_QML "${SHELL_QML}")
    file(WRITE "${CMAKE_BINARY_DIR}/qml/shell.qml" "${SHELL_QML}")
    install(FILES "${CMAKE_BINARY_DIR}/qml/shell.qml" DESTINATION "${INSTALL_QSCONFDIR}")

    install(FILES LICENSE DESTINATION "${INSTALL_QSCONFDIR}")
endif()
