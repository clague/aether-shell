#pragma once

#include <qqmlintegration.h>
#include <qqmlparserstatus.h>
#include <qquickattachedpropertypropagator.h>

#include "anim.hpp"
#include "rootnodes.hpp"

namespace aether::shell::config {

class Tokens : public QQuickAttachedPropertyPropagator, public QQmlParserStatus {
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    QML_ELEMENT
    QML_UNCREATABLE("")
    QML_ATTACHED(Tokens)

    Q_PROPERTY(QString screen READ screen WRITE inheritScreen NOTIFY sourceChanged)
    // Multiplies every Tokens.font size for this item and its children. A window that wants
    // larger type than the rest of the shell sets it once on its root; 1 is the configured
    // size. Icons scale with the text so rows keep their proportions.
    Q_PROPERTY(qreal fontScale READ fontScale WRITE inheritFontScale NOTIFY sourceChanged)
    Q_PROPERTY(const aether::shell::config::AppearanceRounding* rounding READ rounding NOTIFY sourceChanged)
    Q_PROPERTY(const aether::shell::config::AppearanceSpacing* spacing READ spacing NOTIFY sourceChanged)
    Q_PROPERTY(const aether::shell::config::AppearancePadding* padding READ padding NOTIFY sourceChanged)
    Q_PROPERTY(const aether::shell::config::AppearanceTransparency* transparency READ transparency NOTIFY sourceChanged)
    Q_PROPERTY(const aether::shell::config::SizeTokens* sizes READ sizes NOTIFY sourceChanged)
    Q_PROPERTY(const aether::shell::config::FontTokens* font READ font NOTIFY sourceChanged)
    Q_PROPERTY(const aether::shell::config::AnimTokens* anim READ anim CONSTANT)

public:
    explicit Tokens(QObject* parent = nullptr);

    [[nodiscard]] QString screen() const;
    void inheritScreen(const QString& screen);

    [[nodiscard]] qreal fontScale() const;
    void inheritFontScale(qreal scale);

    [[nodiscard]] const AppearanceRounding* rounding() const;
    [[nodiscard]] const AppearanceSpacing* spacing() const;
    [[nodiscard]] const AppearancePadding* padding() const;
    [[nodiscard]] static const AppearanceTransparency* transparency();

    [[nodiscard]] const SizeTokens* sizes() const;
    [[nodiscard]] const FontTokens* font() const;
    [[nodiscard]] static const AnimTokens* anim();

    [[nodiscard]] Q_INVOKABLE static TokensRoot* forScreen(const QString& screen);

    static Tokens* qmlAttachedProperties(QObject* object);

    void classBegin() override;
    void componentComplete() override;

signals:
    void sourceChanged();

protected:
    void attachedParentChange(
        QQuickAttachedPropertyPropagator* newParent, QQuickAttachedPropertyPropagator* oldParent) override;

private:
    void propagateScreen();
    void propagateFontScale();

    bool m_complete = false;
    QString m_screen;
    qreal m_fontScale = 1;
    ConfigRoot* m_config = nullptr;
    TokensRoot* m_tokens = nullptr;
};

} // namespace aether::shell::config
