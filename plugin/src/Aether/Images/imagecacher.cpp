#include "imagecacher.hpp"

#include <qcryptographichash.h>
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qhash.h>
#include <qimage.h>
#include <qimagereader.h>
#include <qloggingcategory.h>
#include <qmutex.h>
#include <qpainter.h>
#include <qsavefile.h>
#include <qthreadpool.h>

namespace {

Q_LOGGING_CATEGORY(lcCacher, "aether.images.cacher", QtInfoMsg)

} // namespace

namespace aether::images {

using Qt::StringLiterals::operator""_s;

namespace {

// Hashing the source is how a changed file gets a new cache entry, but it reads the whole
// file: 34MB for an 8K wallpaper, and cachePathFor is called more than once per request.
// Size and mtime identify a version just as well and cost a stat.
QString sha256sum(const QString& path) {
    // The cache is keyed by arbitrary source paths, so bound it rather than letting every
    // wallpaper, thumbnail and clipboard image stay hashed for the life of the process.
    constexpr int k_maxCachedHashes = 256;
    static QMutex s_cacheMutex;
    static QHash<QString, QString> s_stamps;
    static QHash<QString, QString> s_hashes;

    const QFileInfo info(path);
    const QString stamp = u"%1:%2"_s.arg(info.size()).arg(info.lastModified().toMSecsSinceEpoch());

    {
        const QMutexLocker locker(&s_cacheMutex);
        if (s_stamps.value(path) == stamp) {
            if (const auto it = s_hashes.constFind(path); it != s_hashes.constEnd())
                return it.value();
        }
    }

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        qCWarning(lcCacher).noquote() << "sha256sum: failed to open" << path;
        return {};
    }

    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(&file);
    file.close();

    const QString result = QString::fromLatin1(hash.result().toHex());
    {
        const QMutexLocker locker(&s_cacheMutex);
        if (s_hashes.size() >= k_maxCachedHashes && !s_stamps.contains(path)) {
            // Any entry will do: this is a cache, not a correctness store. Evicting the first
            // iterator keeps the cost O(1) instead of tracking an LRU on every lookup.
            const auto victim = s_stamps.begin();
            s_hashes.remove(victim.key());
            s_stamps.erase(victim);
        }
        s_stamps.insert(path, stamp);
        s_hashes.insert(path, result);
    }
    return result;
}

QString fillSuffix(ImageCacher::FillMode fillMode) {
    switch (fillMode) {
    case ImageCacher::FillMode::Crop:
        return u"crop"_s;
    case ImageCacher::FillMode::Fit:
        return u"fit"_s;
    default:
        return u"stretch"_s;
    }
}

} // namespace

const QString& ImageCacher::cacheDir() {
    static const QString k_dir = [] {
        QString cache = qEnvironmentVariable("XDG_CACHE_HOME");
        if (cache.isEmpty())
            cache = QDir::homePath() + u"/.cache"_s;
        return cache + u"/aether/imagecache"_s;
    }();
    return k_dir;
}

QString ImageCacher::cachePathFor(const QString& sourcePath, const QSize& size, FillMode fillMode) {
    const QString sha = sha256sum(sourcePath);
    if (sha.isEmpty())
        return {};

    const QString filename = u"%1@%2x%3-%4.png"_s.arg(
        sha, QString::number(size.width()), QString::number(size.height()), fillSuffix(fillMode));

    return cacheDir() + u'/' + filename;
}

ImageCacher* ImageCacher::instance() {
    static ImageCacher s_instance;
    return &s_instance;
}

ImageCacher::ImageCacher(QObject* parent)
    : QObject(parent) {}

void ImageCacher::schedule(const QString& sourcePath, const QSize& size, FillMode fillMode) {
    schedule(sourcePath, cachePathFor(sourcePath, size, fillMode), size, fillMode);
}

void ImageCacher::schedule(const QString& sourcePath, const QString& cachePath, const QSize& size, FillMode fillMode) {
    if (cachePath.isEmpty())
        return;

    {
        const QMutexLocker locker(&m_mutex);
        if (m_inflight.contains(cachePath))
            return;
        m_inflight.insert(cachePath);
    }

    QThreadPool::globalInstance()->start([this, sourcePath, cachePath, size, fillMode] {
        runJob(sourcePath, cachePath, size, fillMode);
        const QMutexLocker locker(&m_mutex);
        // NOLINTNEXTLINE(clang-analyzer-core.CallAndMessage) m_inflight is a value member, not a pointer
        m_inflight.remove(cachePath);
    });
}

void ImageCacher::runJob(const QString& sourcePath, const QString& cachePath, const QSize& size, FillMode fillMode) {
    if (QFile::exists(cachePath)) {
        return;
    }

    Qt::AspectRatioMode scaleMode;
    switch (fillMode) {
    case FillMode::Crop:
        scaleMode = Qt::KeepAspectRatioByExpanding;
        break;
    case FillMode::Fit:
        scaleMode = Qt::KeepAspectRatio;
        break;
    case FillMode::Stretch:
        scaleMode = Qt::IgnoreAspectRatio;
        break;
    }

    // Ask the reader for the size we are going to draw, instead of decoding the file whole and
    // scaling afterwards: thumbnails of an 8K wallpaper would each hold it at 130MB on the way.
    QImageReader reader(sourcePath);
    reader.setAutoTransform(true);
    const auto sourceSize = reader.size();
    if (sourceSize.isValid() && !sourceSize.isEmpty()) {
        QSize decodeSize = size;
        if (fillMode != FillMode::Stretch)
            decodeSize = sourceSize.scaled(size, scaleMode);
        if (decodeSize.isValid() && !decodeSize.isEmpty())
            reader.setScaledSize(decodeSize);
    }

    QImage image = reader.read();
    if (image.isNull()) {
        qCWarning(lcCacher).noquote() << "Failed to decode source" << sourcePath;
        return;
    }

    image.convertTo(QImage::Format_ARGB32);
    image = image.scaled(size, scaleMode, Qt::SmoothTransformation);

    if (image.isNull()) {
        qCWarning(lcCacher).noquote() << "Failed to scale" << sourcePath;
        return;
    }

    QImage canvas;
    if (fillMode == FillMode::Stretch) {
        canvas = image;
    } else {
        canvas = QImage(size, QImage::Format_ARGB32);
        canvas.fill(Qt::transparent);

        QPainter painter(&canvas);
        painter.drawImage((size.width() - image.width()) / 2, (size.height() - image.height()) / 2, image);
        painter.end();
    }

    const QString parent = QFileInfo(cachePath).absolutePath();
    if (!QDir().mkpath(parent)) {
        qCWarning(lcCacher).noquote() << "Failed to create cache dir" << parent;
        return;
    }

    QSaveFile saveFile(cachePath);
    if (!saveFile.open(QIODevice::WriteOnly) || !canvas.save(&saveFile, "PNG") || !saveFile.commit()) {
        qCWarning(
            lcCacher, "Failed to save to %s: %s", qUtf8Printable(cachePath), qUtf8Printable(saveFile.errorString()));
        return;
    }

    qCDebug(lcCacher).noquote() << "Saved to" << cachePath;
}

} // namespace aether::images
