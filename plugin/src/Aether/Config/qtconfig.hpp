#pragma once

#include <qstring.h>

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace aether::shell::config {

// How Qt applications look and behave. These are read by Aether's own Qt platform theme
// (plugin/src/Aether/QtTheme), not by the shell, so the keys mirror what that theme can apply;
// an empty string or a zero means "leave it to the session" rather than "zero".
class QtConfig : public settings::ObjectNode {
    CONFIG_NODE(QtConfig, settings::ObjectNode)

    // "auto" lets the theme choose (Kvantum when configured, then the CLI's style, then Fusion).
    CONFIG_PROPERTY(QString, style, u"auto"_s)
    // Empty follows kdeglobals, which is the desktop's own icon setting.
    CONFIG_PROPERTY(QString, iconTheme, QString())

    // Empty family or zero size leaves the font to fontconfig, which is where the shell's own
    // "App fonts" page writes.
    CONFIG_PROPERTY(QString, font, QString())
    CONFIG_PROPERTY(int, fontSize, 0)
    CONFIG_PROPERTY(QString, fontFixed, QString())
    CONFIG_PROPERTY(int, fontFixedSize, 0)

    CONFIG_PROPERTY(bool, menusHaveIcons, true)
    CONFIG_PROPERTY(bool, shortcutsInContextMenus, true)

    // Qt::ToolButtonStyle: 0 icon only, 1 text only, 2 text beside icon, 3 text under icon.
    CONFIG_PROPERTY(int, toolButtonStyle, 2)
    CONFIG_PROPERTY(int, wheelScrollLines, 3)
    CONFIG_PROPERTY(int, cursorFlashTime, 1000)
    CONFIG_PROPERTY(int, doubleClickInterval, 400)
};

} // namespace aether::shell::config
