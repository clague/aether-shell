#include "aethertheme.hpp"

#include <qapplication.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qfilesystemwatcher.h>
#include <qicon.h>
#include <qiodevice.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qjsonvalue.h>
#include <qloggingcategory.h>
#include <qpa/qwindowsysteminterface.h>
#include <qstandardpaths.h>
#include <qstylefactory.h>
#include <qtimer.h>

#include <utility>

#include "aetherpalette.hpp"

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

} // namespace

AetherTheme::AetherTheme()
    : m_schemePath(stateDir() + u"/scheme.json"_s)
    , m_configPath(configPath()) {
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

    // A style the config names but the system does not have would leave Qt with no style at all,
    // so it only becomes the hint when the factory can actually create it.
    const QString style = theme.value(u"style"_s).toString();
    m_styleNames = !style.isEmpty() && QStyleFactory::keys().contains(style, Qt::CaseInsensitive) ? QStringList{ style }
                                                                                                  : QStringList();

    const QJsonObject misc = root.value(u"misc"_s).toObject();
    m_showIconsInMenus = misc.value(u"menusHaveIcons"_s).toBool(true);
    m_showShortcutsInMenus = misc.value(u"shortcutsForContextMenus"_s).toBool(true);
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
        if (m_palette)
            QApplication::setPalette(*m_palette);
        if (m_font)
            QApplication::setFont(*m_font);
    }

    QWindowSystemInterface::handleThemeChange();
}

} // namespace aether::theme
