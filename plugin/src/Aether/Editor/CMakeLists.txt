qml_module(aether-editor
    URI Aether.Editor
    SOURCES
        luahighlighter.cpp
        luahighlighter.hpp
        lualsp.cpp
        lualsp.hpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
)
