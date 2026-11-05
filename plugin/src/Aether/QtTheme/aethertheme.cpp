#include "aethertheme.hpp"

#include <qapplication.h>
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qfilesystemwatcher.h>
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

// The caelestia CLI writes this for the Qt theme it expects to be present. Reading it keeps
// Aether's engine a drop-in for that setup: the colour scheme comes from scheme.json, while the
// font, icon theme and widget style come from here.
QString configPath() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + u"/qtengine/config.json"_s;
}

// kvantummanager writes this. Its [General] theme is the only signal in the tree that a person
// chose a widget style by hand -- the style named in the CLI's config is regenerated from a
// template on every scheme change, so it is a default, not a preference.
// The shell's own settings. This is the only place a style choice can live: the CLI regenerates
// ~/.config/qtengine/config.json from a template on every scheme change, so a value written there
// is gone by the next theme switch.
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

// Writes atomically, and only when the bytes differ: every Qt application runs this at startup,
// and a needless rewrite would wake every KColorScheme watcher on the desktop.
bool writeIfChanged(const QString& path, const QByteArray& body) {
    QFile existing(path);
    if (existing.open(QIODevice::ReadOnly) && existing.readAll() == body)
        return true;

    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly))
        return false;
    file.write(body);
    return file.commit();
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
    Q_UNUSED(type)
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
    case StyleNames:
        if (!m_styleNames.isEmpty())
            return m_styleNames;
        break;
    case ShowIconsInMenus:
        return m_showIconsInMenus;
    case ShowShortcutsInContextMenus:
        return m_showShortcutsInMenus;
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
    m_showIconsInMenus = true;
    m_showShortcutsInMenus = true;

    m_generatedSchemePath.clear();
    QFile scheme(m_schemePath);
    if (scheme.open(QIODevice::ReadOnly)) {
        if (auto parsed = schemeFromJson(scheme.readAll())) {
            m_light = parsed->light;
            m_palette = std::move(parsed->palette);

            // Aether's own copy in the KDE format, written beside the scheme it is derived from.
            // KColorScheme reads this file, so it has to be somewhere Aether owns rather than a
            // by-product of the CLI: same directory as scheme.json, rewritten when the scheme is.
            const QString path = stateDir() + u"/aether.colors"_s;
            const QByteArray body = kdeColorScheme(parsed->colours, u"Aether"_s);
            if (writeIfChanged(path, body))
                m_generatedSchemePath = path;
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
    m_colorSchemePath = !m_generatedSchemePath.isEmpty() ? m_generatedSchemePath : colorSchemePath(kde);
    qApp->setProperty("KDE_COLOR_SCHEME_PATH", m_colorSchemePath.isEmpty() ? QVariant() : m_colorSchemePath);

    QFile shellConfig(m_shellConfigPath);
    if (shellConfig.open(QIODevice::ReadOnly))
        m_configuredQtStyle = shellQtStyle(shellConfig.readAll());
    else
        m_configuredQtStyle.clear();

    m_styleNames = resolveStyle();

    // kdeglobals wins: it is the desktop's icon setting, and the CLI's file only ever holds the
    // Papirus template value it was generated from. Overriding the first with the second is what
    // made Qt apps show Papirus icons in a session whose icons were something else.
    m_iconTheme = kdeIconTheme();
    if (m_iconTheme.isEmpty())
        m_iconTheme = m_configuredIconTheme;
    if (m_iconTheme.isEmpty())
        m_iconTheme = m_light ? u"Papirus-Light"_s : u"Papirus-Dark"_s;

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

    const QJsonObject misc = root.value(u"misc"_s).toObject();
    m_showIconsInMenus = misc.value(u"menusHaveIcons"_s).toBool(true);
    m_showShortcutsInMenus = misc.value(u"shortcutsForContextMenus"_s).toBool(true);
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
    if (!m_configuredQtStyle.isEmpty() && m_configuredQtStyle.compare(u"auto"_s, Qt::CaseInsensitive) != 0) {
        if (QStyleFactory::keys().contains(m_configuredQtStyle, Qt::CaseInsensitive))
            return { m_configuredQtStyle };
        qCWarning(lcTheme) << "Configured Qt style" << m_configuredQtStyle
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
    }

    QWindowSystemInterface::handleThemeChange();
}

} // namespace aether::theme
