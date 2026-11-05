# A Qt platform theme, not a QML module: Qt loads it by the key in aether.json when
# QT_QPA_PLATFORMTHEME names it, so there is no QML side and no qml_module() here.
#
# GuiPrivate is required for the same reason every unix platform theme needs it: the base class
# that supplies fonts, menus and file dialogs (QGenericUnixTheme) is a private header. That
# binding is intentional here, so the warning Qt prints for it is noise.
set(QT_NO_PRIVATE_MODULE_WARNING ON)
find_package(Qt6 REQUIRED COMPONENTS Widgets GuiPrivate)

add_library(aether-qt-theme MODULE
    aethertheme.hpp
    aethertheme.cpp
    aetherpalette.hpp
    aetherpalette.cpp
    aetherstyle.hpp
    aetherstyle.cpp
    thememain.cpp
    aether.json
)

set_target_properties(aether-qt-theme PROPERTIES
    AUTOMOC ON
    OUTPUT_NAME aethertheme
    # Qt looks in <plugin path>/platformthemes, so the output mirrors an install tree and
    # QT_PLUGIN_PATH can point at build/plugins unchanged.
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/plugins/platformthemes"
)

target_link_libraries(aether-qt-theme PRIVATE
    Qt::Core
    Qt::Gui
    Qt::GuiPrivate
    Qt::Widgets
)

install(TARGETS aether-qt-theme DESTINATION "${INSTALL_QTPLUGINDIR}/platformthemes")
