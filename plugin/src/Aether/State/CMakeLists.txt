qml_module(aether-state
    URI Aether.State
    INCLUDE_PREFIX state
    SOURCES
        common.cpp
        rootnodes.cpp
    DEPENDENCIES
        Aether.Settings
)
target_link_libraries(aether-state PUBLIC aether-settings)
