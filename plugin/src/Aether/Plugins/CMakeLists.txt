qml_module(aether-plugins
    URI Aether.Plugins
    SOURCES
        plugins.cpp
        pluginmanifest.cpp
        pluginmodule.cpp
        pluginurlinterceptor.cpp
        entrypoint.cpp
        entrypointloader.cpp
        settingsobject.cpp
        settingmeta.cpp
    QML_SINGLETONS
        Plugins.qml
    LIBRARIES
        Qt::Quick
)

# Bake the shell version in so plugin requirements can be checked against it
target_compile_definitions(aether-plugins PRIVATE AETHER_VERSION="${AETHER_DISPLAY_VERSION}")
