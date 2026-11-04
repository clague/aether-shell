#pragma once

#include <qcolor.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquicktextdocument.h>
#include <qsyntaxhighlighter.h>
#include <qvariant.h>

#include <memory>

namespace aether::shell::editor {

// Lua syntax highlighting for a Qt Quick TextEdit/TextArea. The formats' colours are exposed as
// properties so the page can bind them to the active palette; changing one re-highlights.
class LuaHighlighter : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQuickTextDocument* textDocument READ textDocument WRITE setTextDocument NOTIFY textDocumentChanged)
    Q_PROPERTY(QColor keywordColor READ keywordColor WRITE setKeywordColor NOTIFY coloursChanged)
    Q_PROPERTY(QColor builtinColor READ builtinColor WRITE setBuiltinColor NOTIFY coloursChanged)
    Q_PROPERTY(QColor stringColor READ stringColor WRITE setStringColor NOTIFY coloursChanged)
    Q_PROPERTY(QColor numberColor READ numberColor WRITE setNumberColor NOTIFY coloursChanged)
    Q_PROPERTY(QColor commentColor READ commentColor WRITE setCommentColor NOTIFY coloursChanged)
    Q_PROPERTY(QColor errorColor READ errorColor WRITE setErrorColor NOTIFY coloursChanged)
    Q_PROPERTY(QColor warningColor READ warningColor WRITE setWarningColor NOTIFY coloursChanged)
    Q_PROPERTY(QColor infoColor READ infoColor WRITE setInfoColor NOTIFY coloursChanged)
    // Diagnostics from the language server: { line, character, endLine, endCharacter, severity }.
    // They are drawn as wave underlines on top of the syntax colours.
    Q_PROPERTY(QVariantList diagnostics READ diagnostics WRITE setDiagnostics NOTIFY diagnosticsChanged)

public:
    explicit LuaHighlighter(QObject* parent = nullptr);
    ~LuaHighlighter() override;

    [[nodiscard]] QQuickTextDocument* textDocument() const;
    void setTextDocument(QQuickTextDocument* document);

    [[nodiscard]] QColor keywordColor() const;
    void setKeywordColor(const QColor& colour);

    [[nodiscard]] QColor builtinColor() const;
    void setBuiltinColor(const QColor& colour);

    [[nodiscard]] QColor stringColor() const;
    void setStringColor(const QColor& colour);

    [[nodiscard]] QColor numberColor() const;
    void setNumberColor(const QColor& colour);

    [[nodiscard]] QColor commentColor() const;
    void setCommentColor(const QColor& colour);

    [[nodiscard]] QColor errorColor() const;
    void setErrorColor(const QColor& colour);

    [[nodiscard]] QColor warningColor() const;
    void setWarningColor(const QColor& colour);

    [[nodiscard]] QColor infoColor() const;
    void setInfoColor(const QColor& colour);

    [[nodiscard]] QVariantList diagnostics() const;
    void setDiagnostics(const QVariantList& diagnostics);

signals:
    void textDocumentChanged();
    void coloursChanged();
    void diagnosticsChanged();

private:
    class Highlighter;
    class Formats;

    QQuickTextDocument* m_document = nullptr;
    QVariantList m_diagnostics;
    std::unique_ptr<Formats> m_formats;
    std::unique_ptr<Highlighter> m_highlighter;
};

} // namespace aether::shell::editor
