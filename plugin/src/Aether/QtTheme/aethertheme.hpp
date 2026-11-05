#pragma once

#include <qfont.h>
#include <qobject.h>
#include <qpalette.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

#include <optional>

#if __has_include(<private/qgenericunixtheme_p.h>)
#include <private/qgenericunixtheme_p.h>
#else
#include <private/qgenericunixthemes_p.h>
#endif

class QFileSystemWatcher;
class QTimer;

namespace aether::theme {

// A Qt platform theme that reads the scheme Aether's shell is already using, so a Qt application
// looks like the desktop around it without a second theme engine installed.
//
// Qt asks for the palette, fonts and hints once, at startup, and again only when it is told the
// theme changed. This class therefore owns the whole cycle: it reads the files, watches them for
// replacement, and re-applies everything when they move.
//
// QPlatformTheme is a Q_GADGET rather than a QObject, so the QObject half is a separate base: the
// file watcher and debounce timer need one, and the palette override does not.
class AetherTheme final : public QObject, public QGenericUnixTheme {
    Q_OBJECT

public:
    AetherTheme();
    ~AetherTheme() override;

    Q_DISABLE_COPY_MOVE(AetherTheme)

    [[nodiscard]] const QPalette* palette(Palette type = SystemPalette) const override;
    [[nodiscard]] const QFont* font(Font type = SystemFont) const override;
    [[nodiscard]] QVariant themeHint(ThemeHint hint) const override;

private:
    void startWatching();
    void watch(const QString& path);
    void scheduleReload();
    void reload();
    void applyConfig(const QByteArray& json);
    void apply();
    [[nodiscard]] QStringList resolveStyle() const;

    QString m_schemePath;
    QString m_configPath;
    QString m_kvantumConfigPath;
    QFileSystemWatcher* m_watcher = nullptr;
    QTimer* m_debounce = nullptr;

    std::optional<QPalette> m_palette;
    std::optional<QFont> m_font;
    std::optional<QFont> m_fixedFont;
    QStringList m_styleNames;
    QString m_configuredStyle;
    QString m_iconTheme;
    QString m_configuredIconTheme;
    bool m_light = true;
    bool m_showIconsInMenus = true;
    bool m_showShortcutsInMenus = true;

    // The application object is still being filled in while the theme is constructed, so
    // pushing a palette into it then would be overwritten a moment later.
    bool m_started = false;
};

} // namespace aether::theme
