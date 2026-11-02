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

# What the shell shows as its version. A tagged checkout keeps its tag; an untagged one --
# including the gate builds above, which deliberately hide the tag -- reports `r<short sha>`,
# so the About page names the commit it is actually running instead of 0.0.0. The revision is
# read from the local repository only: `rev-parse` needs no network, which is the property the
# empty gate values protect.
if(AETHER_VERSION_WAS_UNSET)
    execute_process(
        COMMAND git -C "${CMAKE_CURRENT_SOURCE_DIR}" rev-parse --short=7 HEAD
        OUTPUT_VARIABLE AETHER_LOCAL_REVISION
        RESULT_VARIABLE AETHER_LOCAL_REVISION_RESULT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )

    if(AETHER_LOCAL_REVISION_RESULT EQUAL 0 AND NOT "${AETHER_LOCAL_REVISION}" STREQUAL "")
        set(AETHER_DISPLAY_VERSION "r${AETHER_LOCAL_REVISION}")
    else()
        set(AETHER_DISPLAY_VERSION "${VERSION}")
    endif()
else()
    set(AETHER_DISPLAY_VERSION "${VERSION}")
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

    # Runtime helpers (bt-agent, app-fonts, doctor, display-draft, wifi-connect,
    # startup-shell) are resolved through Quickshell.shellPath("scripts/..."), so an
    # installed shell without them fails every one of those features. A directory install
    # preserves the executable bits.
    install(DIRECTORY scripts DESTINATION "${INSTALL_QSCONFDIR}"
        PATTERN "__pycache__" EXCLUDE PATTERN "*.pyc" EXCLUDE)
    # wifi-connect.sh is executed directly (Nmcli.runWifiConnect), and a directory install
    # gives it 0644; PROGRAMS sets the executable bit back.
    install(PROGRAMS scripts/wifi-connect.sh DESTINATION "${INSTALL_QSCONFDIR}/scripts")

    install(PROGRAMS assets/wrap_term_launch.sh DESTINATION "${INSTALL_QSCONFDIR}/assets")

    file(READ shell.qml SHELL_QML)
    string(REPLACE "settings.watchFiles: true" "settings.watchFiles: false" SHELL_QML "${SHELL_QML}")
    file(WRITE "${CMAKE_BINARY_DIR}/qml/shell.qml" "${SHELL_QML}")
    install(FILES "${CMAKE_BINARY_DIR}/qml/shell.qml" DESTINATION "${INSTALL_QSCONFDIR}")

    install(FILES LICENSE DESTINATION "${INSTALL_QSCONFDIR}")
endif()
