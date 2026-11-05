#include "aethertheme.hpp"

#include <qapplication.h>
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qfilesystemwatcher.h>
#include <qfontinfo.h>
#include <qicon.h>
#include <qiodevice.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qjsonvalue.h>
#include <qlibraryinfo.h>
#include <qloggingcategory.h>
#include <qpa/qwindowsysteminterface.h>
#include <qsavefile.h>
#include <qstandardpaths.h>
#include <qstyle.h>
#include <qstylefactory.h>
#include <qtenvironmentvariables.h>
#include <qtimer.h>

#include <algorithm>
#include <array>
#include <utility>

#include "aetherpalette.hpp"
#include "aetherstyle.hpp"

namespace aether::theme {

using Qt::StringLiterals::operator""_s;

namespace {

Q_LOGGING_CATEGORY(lcTheme, "aether.qt.theme", QtInfoMsg)

// Both the shell and the CLI write these files atomically, so a change arrives as a burst of
// inotify events: one for the temp file, one for the rename. Waiting a moment collapses them and
// avoids reading a file that the next rename is about to replace.
constexpr int k_reloadDelayMs = 150;

QString stateDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericStateLocation) + u"/caelestia"_s;
}

// qtengine writes this when the user has it installed. Reading it keeps Aether's engine a
// drop-in for that setup: the colour scheme comes from scheme.json, while the font, icon theme
// and widget style may come from here.
QString configPath() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + u"/qtengine/config.json"_s;
}

// kvantummanager writes this. Its [General] theme is the only signal in the tree that a person
// chose a widget style by hand -- the style named in the generated Qt config is a default, not
// a preference.
// The shell's own settings. This is the only place a style choice can live: a generated
// qtengine config is replaced on theme changes, so a value written there does not survive.
QString shellConfigPath() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + u"/caelestia/shell.json"_s;
}

// The desktop's own icon theme. KDE writes it here and every Plasma tool reads it, so a session
// that has ever been configured in system settings has the user's real choice -- while the CLI's
// Qt config only ever holds the Papirus template value it was generated from.
QString kdeglobalsPath() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + u"/kdeglobals"_s;
}

// The KDE colour scheme file KColorScheme should read: the CLI's copy first (regenerated on every
// scheme change), then whatever kdeglobals names, then nothing.
QString colorSchemePath(const QByteArray& kdeglobals) {
    QString generated =
        QStandardPaths::writableLocation(QStandardPaths::GenericStateLocation) + u"/caelestia/aether.colors"_s;
    if (QFileInfo::exists(generated))
        return generated;

    generated =
        QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + u"/qtengine/caelestia.colors"_s;
    if (QFileInfo::exists(generated))
        return generated;

    const QString name = kdeglobals.isEmpty() ? QString() : iniValue(kdeglobals, u"General"_s, u"ColorScheme"_s);
    if (name.isEmpty())
        return {};

    const QString share = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    for (const QString& dir : { share + u"/color-schemes"_s, u"/usr/share/color-schemes"_s }) {
        const QString candidate = dir + u'/' + name + u".colors"_s;
        if (QFileInfo::exists(candidate))
            return candidate;
    }
    return {};
}

// Whether a theme directory exists where the icon spec looks. Only used to avoid naming a theme
// that is not on the machine.
bool iconThemeInstalled(const QString& name) {
    const QString home = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    const std::array dirs = { QDir::homePath() + u"/.icons"_s, home + u"/icons"_s, u"/usr/share/icons"_s };
    return std::ranges::any_of(dirs, [&name](const QString& dir) {
        return QFileInfo::exists(dir + u'/' + name + u"/index.theme"_s);
    });
}

QString kvantumConfigPath() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + u"/Kvantum/kvantum.kvconfig"_s;
}

// Kvantum keeps themes in the config dir and in its system share dir, and nowhere else: a theme
// under $XDG_DATA_HOME/Kvantum is silently ignored and the style falls back to its built-in
// colours. Confirming the theme resolves is what separates "Kvantum is set up" from "the plugin
// is installed".
QString kvantumTheme(const QString& configPath) {
    if (!QFileInfo::exists(configPath))
        return {};

    QFile file(configPath);
    if (!file.open(QIODevice::ReadOnly))
        return {};

    QString theme = kvantumThemeName(file.readAll());
    if (theme.isEmpty())
        return {};

    // The theme file, not just the directory: a half-written or half-deleted theme still has a
    // folder, and Kvantum answers that with its built-in placeholder colours.
    const QString userTheme = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + u"/Kvantum/"_s +
                              theme + u'/' + theme + u".kvconfig"_s;
    if (QFileInfo::exists(userTheme))
        return theme;

    const QString sharedTheme = u"/usr/share/Kvantum/"_s + theme + u'/' + theme + u".kvconfig"_s;
    return QFileInfo::exists(sharedTheme) ? theme : QString();
}

// Kvantum paints from its own theme file and replaces the application palette in polish(), so
// pushing ours into a running application afterwards would fight it and win: backgrounds from its
// SVG, text from ours. While it is the style, the palette belongs to it. Asked of the running style
// rather than of the hint, because QT_STYLE_OVERRIDE can replace the hint at the last moment.
bool kvantumIsActive() {
    if (qobject_cast<QApplication*>(QCoreApplication::instance()) == nullptr)
        return false;

    const QStyle* style = QApplication::style();
    return style != nullptr && style->objectName().compare(u"kvantum"_s, Qt::CaseInsensitive) == 0;
}

} // namespace

AetherTheme::AetherTheme()
    : m_schemePath(stateDir() + u"/scheme.json"_s)
    , m_configPath(configPath())
    , m_kvantumConfigPath(kvantumConfigPath())
    , m_kdeglobalsPath(kdeglobalsPath())
    , m_shellConfigPath(shellConfigPath()) {
    // Qt reads palette() and font() synchronously, while the application object is still being
    // built, so the first read cannot wait for the event loop.
    reload();

    // Watching has to. A QFileSystemWatcher built in the platform theme's constructor attaches its
    // socket notifier before the event loop exists, and from then on never fires: the file changes
    // and nothing happens. Deferring it one turn of the loop is what makes live reload work.
    QMetaObject::invokeMethod(this, &AetherTheme::startWatching, Qt::QueuedConnection);
}

AetherTheme::~AetherTheme() = default;

void AetherTheme::startWatching() {
    m_watcher = new QFileSystemWatcher(this);
    m_debounce = new QTimer(this);
    m_debounce->setSingleShot(true);
    m_debounce->setInterval(k_reloadDelayMs);

    connect(m_debounce, &QTimer::timeout, this, &AetherTheme::reload);
    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &AetherTheme::scheduleReload);
    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, &AetherTheme::scheduleReload);

    // A running application has already read the startup palette, so later changes are pushed
    // into it by name rather than by Qt asking again.
    m_started = true;

    // Read once more: the scheme may have changed between the constructor and this call.
    reload();
}

// Deliberately no opinion: Qt then takes the font from QFontDatabase, which is fontconfig, which
// is the layer the shell's own "App fonts" page writes. QGenericUnixTheme's answer is a cached
// default (9 pt) built before the font database is ready, and the CLI's config only ever holds a
// template value, so both would override the user's real font with something stale.
const QFont* AetherTheme::font(Font type) const {
    if (type == SystemFont)
        return m_font ? &*m_font : nullptr;

    if (type == FixedFont) {
        if (m_fixedFont)
            return &*m_fixedFont;

        // nullptr here does not mean "ask fontconfig": Qt falls back to the general font, so code
        // and terminals would be drawn in the proportional face. The generic name is resolved
        // through fontconfig when it is used.
        static const QFont k_monospaceFont(QStringLiteral("monospace"));
        return &k_monospaceFont;
    }

    return nullptr;
}

const QPalette* AetherTheme::palette(Palette type) const {
    if (type == SystemPalette && m_palette)
        return &*m_palette;
    return QGenericUnixTheme::palette(type);
}

QVariant AetherTheme::themeHint(ThemeHint hint) const {
    switch (hint) {
    case SystemIconThemeName:
        if (!m_iconTheme.isEmpty())
            return m_iconTheme;
        break;
    case CursorFlashTime:
        return m_settings.cursorFlashTime;
    case MouseDoubleClickInterval:
        return m_settings.doubleClickInterval;
    case ToolButtonStyle:
        return m_settings.toolButtonStyle;
    case WheelScrollLines:
        return m_settings.wheelScrollLines;
    case StyleNames:
        if (!m_styleNames.isEmpty())
            return m_styleNames;
        break;
    case ShowIconsInMenus:
        return m_hasShellSettings ? m_settings.menusHaveIcons : m_configuredMenusHaveIcons;
    case ShowShortcutsInContextMenus:
        return m_hasShellSettings ? m_settings.shortcutsInContextMenus : m_configuredShortcutsInMenus;
    default:
        break;
    }

    return QGenericUnixTheme::themeHint(hint);
}

void AetherTheme::watch(const QString& path) {
    if (path.isEmpty() || m_watcher == nullptr)
        return;

    m_watcher->addPath(path);

    // An atomic write replaces the inode, and a watcher that has lost its path never fires
    // again. Watching the directory is what re-attaches the file after the rename.
    const QString dir = QFileInfo(path).absolutePath();
    if (!dir.isEmpty() && !m_watcher->directories().contains(dir))
        m_watcher->addPath(dir);
}

void AetherTheme::scheduleReload() {
    m_debounce->start();
}

void AetherTheme::reload() {
    // Everything below is re-derived from the files on every pass, so deleting a key restores the
    // default instead of leaving the last applied value behind.
    m_styleNames.clear();
    m_configuredIconTheme.clear();

    QFile scheme(m_schemePath);
    if (scheme.open(QIODevice::ReadOnly)) {
        if (auto parsed = schemeFromJson(scheme.readAll())) {
            m_light = parsed->light;
            m_palette = std::move(parsed->palette);
        } else {
            qCWarning(lcTheme) << "Ignoring unreadable scheme at" << m_schemePath;
        }
    }

    QFile config(m_configPath);
    if (config.open(QIODevice::ReadOnly))
        applyConfig(config.readAll());

    // One read of the session's own settings, used for both the icon theme and the fonts.
    QByteArray kde;
    QFile kdeglobals(m_kdeglobalsPath);
    if (kdeglobals.open(QIODevice::ReadOnly))
        kde = kdeglobals.readAll();

    // KDE applications paint through KColorScheme rather than QPalette -- Dolphin's places panel
    // is one -- and KColorScheme reads this application property when it is set. KDE's own
    // platform theme sets it; without it those applications fall back to a scheme of their own,
    // which is how the sidebar ended up with dark text on a dark background.
    //
    // Ours first, then the CLI's copy for the case where scheme.json is missing, then whatever
    // kdeglobals names.
    m_colorSchemePath = colorSchemePath(kde);
    qApp->setProperty("KDE_COLOR_SCHEME_PATH", m_colorSchemePath.isEmpty() ? QVariant() : m_colorSchemePath);

    QFile shellConfig(m_shellConfigPath);
    m_hasShellSettings = shellConfig.open(QIODevice::ReadOnly);
    m_settings = m_hasShellSettings ? qtSettingsFromJson(shellConfig.readAll()) : QtSettings();

    // A size of 0 means "keep the size the system picked", not a number of our own: the family
    // and the size are independent choices.
    const auto fontFor = [](const QString& family, int size) {
        if (family.isEmpty())
            return std::optional<QFont>();
        // 0 keeps the size fontconfig gives that family; SystemFont() would answer with the
        // general font's size, which is not what a monospace family asks for.
        const int resolved = size > 0 ? size : QFontInfo(QFont(family)).pointSize();
        return std::optional<QFont>(QFont(family, resolved));
    };
    m_font = fontFor(m_settings.font, m_settings.fontSize);
    m_fixedFont = fontFor(m_settings.fontFixed, m_settings.fontFixedSize);

    m_styleNames = resolveStyle();

    // kdeglobals wins: it is the desktop's icon setting, and the CLI's file only ever holds the
    // Papirus template value it was generated from. Overriding the first with the second is what
    // made Qt apps show Papirus icons in a session whose icons were something else.
    // The setting wins, then the session's own icon choice, then the CLI's template value, then
    // Papirus -- and only if Papirus is actually installed, because naming a theme that is not
    // there makes Qt fall back to hicolor while the settings page keeps claiming otherwise.
    m_iconTheme = m_settings.iconTheme;
    if (m_iconTheme.isEmpty())
        m_iconTheme = kdeIconTheme();
    if (m_iconTheme.isEmpty())
        m_iconTheme = m_configuredIconTheme;
    if (m_iconTheme.isEmpty()) {
        const QString guess = m_light ? u"Papirus-Light"_s : u"Papirus-Dark"_s;
        if (iconThemeInstalled(guess))
            m_iconTheme = guess;
    }

    // Re-added every time: whichever file changed, the rename may have dropped its watch.
    watch(m_schemePath);
    watch(m_configPath);
    watch(m_kdeglobalsPath);

    apply();
}

void AetherTheme::applyConfig(const QByteArray& json) {
    const QJsonDocument document = QJsonDocument::fromJson(json);
    if (!document.isObject())
        return;

    const QJsonObject root = document.object();
    const QJsonObject theme = root.value(u"theme"_s).toObject();

    if (const QString icon = theme.value(u"iconTheme"_s).toString(); !icon.isEmpty())
        m_configuredIconTheme = icon;

    m_configuredStyle = theme.value(u"style"_s).toString();

    // The CLI's file still carries these; they are the fallback when the shell's Qt settings say
    // nothing, which is what keeps a machine that never opened the page behaving as before.
    const QJsonObject misc = root.value(u"misc"_s).toObject();
    m_configuredMenusHaveIcons = misc.value(u"menusHaveIcons"_s).toBool(true);
    m_configuredShortcutsInMenus = misc.value(u"shortcutsForContextMenus"_s).toBool(true);
}

QString AetherTheme::kdeIconTheme() const {
    QFile file(m_kdeglobalsPath);
    if (!file.open(QIODevice::ReadOnly))
        return {};
    return iniValue(file.readAll(), u"Icons"_s, u"Theme"_s);
}

QStringList AetherTheme::resolveStyle() const {
    // An override is the user speaking last, and Qt applies it after this hint anyway.
    if (!qEnvironmentVariableIsEmpty("QT_STYLE_OVERRIDE"))
        return {};

    // An explicit choice beats every guess below. A style that is not installed keeps its value in
    // the config and falls through to the automatic chain, so uninstalling Darkly for an afternoon
    // does not silently rewrite the setting.
    if (!m_settings.style.isEmpty() && m_settings.style.compare(u"auto"_s, Qt::CaseInsensitive) != 0) {
        if (QStyleFactory::keys().contains(m_settings.style, Qt::CaseInsensitive))
            return { m_settings.style };
        qCWarning(lcTheme) << "Configured Qt style" << m_settings.style
                           << "is not installed; falling back to the automatic choice";
    }

    // Kvantum is the one style that brings a palette of its own, so it is only chosen when the user
    // has actually configured it: without a theme it paints with built-in placeholder colours, and
    // that looks worse than the Fusion fallback.
    if (!kvantumTheme(m_kvantumConfigPath).isEmpty() &&
        QStyleFactory::keys().contains(u"kvantum"_s, Qt::CaseInsensitive))
        return { u"kvantum"_s };

    // Anything else the config names has to exist, or Qt would be left with no style at all.
    if (!m_configuredStyle.isEmpty() && QStyleFactory::keys().contains(m_configuredStyle, Qt::CaseInsensitive))
        return { m_configuredStyle };

    // Empty means "ask QGenericUnixTheme", which answers Fusion on a session that is not KDE.
    return {};
}

void AetherTheme::apply() {
    if (!m_iconTheme.isEmpty())
        QIcon::setThemeName(m_iconTheme);

    if (!m_started)
        return;

    // A running application read the palette once, at startup, and nothing will make it look
    // again unless it is told. setPalette posts PaletteChange to every widget that has not set
    // its own palette; handleThemeChange is what QtQuick listens to.
    if (qobject_cast<QApplication*>(QCoreApplication::instance()) != nullptr) {
        if (m_palette && !kvantumIsActive())
            QApplication::setPalette(*m_palette);
        if (m_font)
            QApplication::setFont(*m_font);
    }

    QWindowSystemInterface::handleThemeChange();
}

} // namespace aether::theme
