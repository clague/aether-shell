#include "cachingimageprovider.hpp"

#include <qfileinfo.h>
#include <qimage.h>
#include <qimagereader.h>
#include <qloggingcategory.h>
#include <qrunnable.h>
#include <qthreadpool.h>

#include <utility>

#include "imagecacher.hpp"

namespace {

Q_LOGGING_CATEGORY(lcCProv, "aether.images.cacheprovider", QtInfoMsg)

} // namespace

namespace aether::images {

using Qt::StringLiterals::operator""_s;

namespace {

class CachingImageResponse final : public QQuickImageResponse, public QRunnable {
public:
    CachingImageResponse(QString id, const QSize& requestedSize, ImageCacher::FillMode fillMode);

    [[nodiscard]] QQuickTextureFactory* textureFactory() const override;

    [[nodiscard]] QString errorString() const override;

    void run() override;

private:
    void process();

    QString m_id;
    QSize m_requestedSize;
    ImageCacher::FillMode m_fillMode;
    QImage m_image;
    QString m_error;
};

CachingImageResponse::CachingImageResponse(QString id, const QSize& requestedSize, ImageCacher::FillMode fillMode)
    : m_id(std::move(id))
    , m_requestedSize(requestedSize)
    , m_fillMode(fillMode) {
    setAutoDelete(false);
}

QQuickTextureFactory* CachingImageResponse::textureFactory() const {
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

QString CachingImageResponse::errorString() const {
    return m_error;
}

void CachingImageResponse::run() {
    process();
    emit finished();
}

void CachingImageResponse::process() {
    QString path = QString::fromUtf8(m_id.toUtf8().percentDecoded());
    if (!path.startsWith(u'/'))
        path.prepend(u'/');

    if (!QFileInfo::exists(path)) {
        m_error = u"Source file does not exist: "_s + path;
        qCWarning(lcCProv).noquote() << m_error;
        return;
    }

    QSize size = m_requestedSize;
    const bool needsW = size.width() <= 0;
    const bool needsH = size.height() <= 0;

    // If both dimensions are missing, return the original directly
    if (needsW && needsH) {
        qCDebug(lcCProv).noquote() << "Given source size is invalid, returning original:" << path;
        m_image = QImage(path);
        if (m_image.isNull()) {
            m_error = u"Failed to decode source: "_s + path;
            qCWarning(lcCProv).noquote() << m_error;
        }
        return;
    }

    // If one dimension is missing, derive it from the source aspect ratio
    if (needsW || needsH) {
        const QImageReader sourceReader(path);
        const QSize sourceSize = sourceReader.size();
        if (!sourceSize.isValid() || sourceSize.isEmpty()) {
            m_error = u"Could not determine source size for: "_s + path;
            qCWarning(lcCProv).noquote() << m_error;
            return;
        }

        if (needsW)
            size.setWidth(qRound(size.height() * sourceSize.width() / static_cast<qreal>(sourceSize.height())));
        else
            size.setHeight(qRound(size.width() * sourceSize.height() / static_cast<qreal>(sourceSize.width())));
    }

    // Try to use cached image
    const auto cachePath = ImageCacher::cachePathFor(path, size, m_fillMode);
    if (!cachePath.isEmpty()) {
        QImageReader cacheReader(cachePath);
        if (cacheReader.canRead()) {
            m_image = cacheReader.read();
            if (!m_image.isNull())
                return;
        }
    }

    // Schedule cache job (this call will return a scaled image, later ones will use the cache)
    ImageCacher::instance()->schedule(path, cachePath, size, m_fillMode);

    // Decode at the requested size rather than loading the file whole: this path runs on a
    // cache miss, and returning the original here meant a 7680x4320 source allocated 130MB
    // (and kept it in the pixmap cache) for every first request of a new size.
    QImageReader reader(path);
    reader.setAutoTransform(true);
    const auto sourceSize = reader.size();
    if (sourceSize.isValid() && !sourceSize.isEmpty())
        reader.setScaledSize(sourceSize.scaled(size, Qt::KeepAspectRatio));
    m_image = reader.read();

    if (m_image.isNull()) {
        // Some formats refuse scaled reads; fall back to the plain decode so the image still
        // shows, just at full size.
        m_image = QImage(path);
        if (m_image.isNull()) {
            m_error = u"Failed to decode source: "_s + path;
            qCWarning(lcCProv).noquote() << m_error;
        }
    }
}

} // namespace

CachingImageProvider::CachingImageProvider(FillMode fillMode)
    : m_fillMode(fillMode) {}

QQuickImageResponse* CachingImageProvider::requestImageResponse(const QString& id, const QSize& requestedSize) {
    auto* const response = new CachingImageResponse(id, requestedSize, m_fillMode);
    QThreadPool::globalInstance()->start(response);
    return response;
}

} // namespace aether::images
