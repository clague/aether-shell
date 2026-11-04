#pragma once

#include <qcolor.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquicktextdocument.h>
#include <qsyntaxhighlighter.h>

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

signals:
    void textDocumentChanged();
    void coloursChanged();

private:
    class Highlighter;
    class Formats;

    QQuickTextDocument* m_document = nullptr;
    std::unique_ptr<Formats> m_formats;
    std::unique_ptr<Highlighter> m_highlighter;
};

} // namespace aether::shell::editor
