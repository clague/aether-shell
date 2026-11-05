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

std::optional<QFont> readFont(const QJsonObject& theme, const QString& key) {
    const QJsonObject spec = theme.value(key).toObject();
    const QString family = spec.value(u"family"_s).toString();
    if (family.isEmpty())
        return std::nullopt;

    QFont font(family);
    // -1 means "leave it to fontconfig" in the generated config, which is also QFont's default.
    const int size = spec.value(u"size"_s).toInt();
    if (size > 0)
        font.setPointSize(size);
    const int weight = spec.value(u"weight"_s).toInt();
    if (weight > 0)
        font.setWeight(static_cast<QFont::Weight>(weight));
    return font;
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

const QPalette* AetherTheme::palette(Palette type) const {
    if (type == SystemPalette && m_palette)
        return &*m_palette;
    return QGenericUnixTheme::palette(type);
}

const QFont* AetherTheme::font(Font type) const {
    if (type == SystemFont && m_font)
        return &*m_font;
    if (type == FixedFont && m_fixedFont)
        return &*m_fixedFont;
    return QGenericUnixTheme::font(type);
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
    m_font.reset();
    m_fixedFont.reset();
    m_styleNames.clear();
    m_configuredIconTheme.clear();
    m_showIconsInMenus = true;
    m_showShortcutsInMenus = true;

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

    QFile shellConfig(m_shellConfigPath);
    if (shellConfig.open(QIODevice::ReadOnly))
        m_configuredQtStyle = shellQtStyle(shellConfig.readAll());
    else
        m_configuredQtStyle.clear();

    m_styleNames = resolveStyle();

    m_iconTheme = m_configuredIconTheme;
    if (m_iconTheme.isEmpty())
        m_iconTheme = m_light ? u"Papirus-Light"_s : u"Papirus-Dark"_s;

    // Re-added every time: whichever file changed, the rename may have dropped its watch.
    watch(m_schemePath);
    watch(m_configPath);

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

    m_font = readFont(theme, u"font"_s);
    m_fixedFont = readFont(theme, u"fontFixed"_s);

    m_configuredStyle = theme.value(u"style"_s).toString();

    const QJsonObject misc = root.value(u"misc"_s).toObject();
    m_showIconsInMenus = misc.value(u"menusHaveIcons"_s).toBool(true);
    m_showShortcutsInMenus = misc.value(u"shortcutsForContextMenus"_s).toBool(true);
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
        if (m_font)
            QApplication::setFont(*m_font);
    }

    QWindowSystemInterface::handleThemeChange();
}

} // namespace aether::theme
