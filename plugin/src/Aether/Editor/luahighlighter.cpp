#include "luahighlighter.hpp"

#include <qtextdocument.h>
#include <qtextformat.h>

#include <algorithm>
#include <vector>

namespace aether::shell::editor {

using Qt::StringLiterals::operator""_s;

namespace {

const QSet<QString>& keywords() {
    static const QSet<QString> set = {
        u"and"_s,
        u"break"_s,
        u"do"_s,
        u"else"_s,
        u"elseif"_s,
        u"end"_s,
        u"false"_s,
        u"for"_s,
        u"function"_s,
        u"goto"_s,
        u"if"_s,
        u"in"_s,
        u"local"_s,
        u"nil"_s,
        u"not"_s,
        u"or"_s,
        u"repeat"_s,
        u"return"_s,
        u"then"_s,
        u"true"_s,
        u"until"_s,
        u"while"_s,
    };
    return set;
}

const QSet<QString>& builtins() {
    static const QSet<QString> set = {
        u"print"_s,
        u"pairs"_s,
        u"ipairs"_s,
        u"tostring"_s,
        u"tonumber"_s,
        u"type"_s,
        u"pcall"_s,
        u"xpcall"_s,
        u"error"_s,
        u"assert"_s,
        u"require"_s,
        u"select"_s,
        u"next"_s,
        u"rawget"_s,
        u"rawset"_s,
        u"setmetatable"_s,
        u"getmetatable"_s,
        u"table"_s,
        u"string"_s,
        u"math"_s,
        u"os"_s,
        u"io"_s,
        u"debug"_s,
        u"coroutine"_s,
    };
    return set;
}

// `[`, zero or more `=`, `[`. `length` includes both brackets.
bool longBracket(const QString& text, int index, int& level, int& length) {
    if (index >= text.size() || text[index] != u'[')
        return false;

    int i = index + 1;
    while (i < text.size() && text[i] == u'=')
        ++i;

    if (i >= text.size() || text[i] != u'[')
        return false;

    level = i - index - 1;
    length = i - index + 1;
    return true;
}

int findLongClose(const QString& text, int from, int level) {
    return text.indexOf(u']' + QString(level, u'=') + u']', from);
}

constexpr int stringStateBase = 1;    // 1 + level
constexpr int commentStateBase = 101; // 101 + level
constexpr int maxLevel = 20;

} // namespace

class LuaHighlighter::Formats {
public:
    struct Diagnostic {
        int line = 0;
        int character = 0;
        int endLine = 0;
        int endCharacter = 0;
        int severity = 3;
    };

    QTextCharFormat keyword;
    QTextCharFormat builtin;
    QTextCharFormat string;
    QTextCharFormat number;
    QTextCharFormat comment;
    QTextCharFormat error;
    QTextCharFormat warning;
    QTextCharFormat info;
    std::vector<Diagnostic> diagnostics;

    [[nodiscard]] const QTextCharFormat& forSeverity(int severity) const {
        switch (severity) {
        case 1:
            return error;
        case 2:
            return warning;
        default:
            return info;
        }
    }
};

class LuaHighlighter::Highlighter : public QSyntaxHighlighter {
public:
    Highlighter(QTextDocument* document, const Formats* formats)
        : QSyntaxHighlighter(document)
        , m_formats(formats) {}

protected:
    void highlightBlock(const QString& text) override {
        m_applied.clear();
        int i = 0;
        const int n = text.size();

        // Continue a long string/comment from the previous line.
        const int state = previousBlockState();
        if (state >= stringStateBase && state <= stringStateBase + maxLevel) {
            const int level = state - stringStateBase;
            const int end = findLongClose(text, 0, level);
            const int closeLength = level + 2;
            if (end < 0) {
                apply(0, n, m_formats->string);
                setCurrentBlockState(state);
                return;
            }
            apply(0, end + closeLength, m_formats->string);
            i = end + closeLength;
        } else if (state >= commentStateBase && state <= commentStateBase + maxLevel) {
            const int level = state - commentStateBase;
            const int end = findLongClose(text, 0, level);
            const int closeLength = level + 2;
            if (end < 0) {
                apply(0, n, m_formats->comment);
                setCurrentBlockState(state);
                return;
            }
            apply(0, end + closeLength, m_formats->comment);
            i = end + closeLength;
        }

        setCurrentBlockState(0);

        while (i < n) {
            const QChar c = text[i];

            if (c == u'-' && i + 1 < n && text[i + 1] == u'-') {
                int level = 0;
                int length = 0;
                if (longBracket(text, i + 2, level, length)) {
                    const int end = findLongClose(text, i + 2 + length, level);
                    const int closeLength = level + 2;
                    if (end < 0) {
                        apply(i, n - i, m_formats->comment);
                        setCurrentBlockState(commentStateBase + qMin(level, maxLevel));
                        return;
                    }
                    apply(i, end + closeLength - i, m_formats->comment);
                    i = end + closeLength;
                    continue;
                }
                apply(i, n - i, m_formats->comment);
                return;
            }

            if (c == u'[') {
                int level = 0;
                int length = 0;
                if (longBracket(text, i, level, length)) {
                    const int end = findLongClose(text, i + length, level);
                    const int closeLength = level + 2;
                    if (end < 0) {
                        apply(i, n - i, m_formats->string);
                        setCurrentBlockState(stringStateBase + qMin(level, maxLevel));
                        return;
                    }
                    apply(i, end + closeLength - i, m_formats->string);
                    i = end + closeLength;
                    continue;
                }
            }

            if (c == u'"' || c == u'\'') {
                int j = i + 1;
                while (j < n) {
                    if (text[j] == u'\\') {
                        j += 2;
                        continue;
                    }
                    if (text[j] == c) {
                        ++j;
                        break;
                    }
                    ++j;
                }
                apply(i, qMin(j, n) - i, m_formats->string);
                i = j;
                continue;
            }

            if (c.isDigit() || (c == u'.' && i + 1 < n && text[i + 1].isDigit())) {
                int j = i;
                while (j < n && (text[j].isLetterOrNumber() || text[j] == u'.' || text[j] == u'_'))
                    ++j;
                apply(i, j - i, m_formats->number);
                i = j;
                continue;
            }

            if (c.isLetter() || c == u'_') {
                int j = i;
                while (j < n && (text[j].isLetterOrNumber() || text[j] == u'_'))
                    ++j;
                const QString word = text.mid(i, j - i);
                if (keywords().contains(word))
                    apply(i, j - i, m_formats->keyword);
                else if (builtins().contains(word))
                    apply(i, j - i, m_formats->builtin);
                i = j;
                continue;
            }

            ++i;
        }

        applyDiagnostics(text);
    }

private:
    struct AppliedFormat {
        int start;
        int end;
        QTextCharFormat format;
    };

    void apply(int start, int length, const QTextCharFormat& format) {
        if (length <= 0 || start < 0)
            return;
        setFormat(start, length, format);
        m_applied.push_back({ start, start + length, format });
    }

    // Diagnostic ranges get a wave underline. The underline is merged into the format that
    // already covers that piece of text, so the syntax colour under the squiggle is kept.
    void applyDiagnostics(const QString& text) {
        const int block = currentBlock().blockNumber();
        for (const Formats::Diagnostic& diagnostic : m_formats->diagnostics) {
            if (block < diagnostic.line || block > diagnostic.endLine)
                continue;

            int start = block == diagnostic.line ? diagnostic.character : 0;
            int end = block == diagnostic.endLine ? diagnostic.endCharacter : text.size();
            if (diagnostic.line == diagnostic.endLine && diagnostic.character == diagnostic.endCharacter)
                end = start + 1;
            start = qBound(0, start, text.size());
            end = qBound(0, end, text.size());
            if (end <= start)
                continue;

            applyUnderline(start, end, m_formats->forSeverity(diagnostic.severity));
        }
    }

    void applyUnderline(int start, int end, const QTextCharFormat& underline) {
        std::vector<int> points = { start, end };
        for (const AppliedFormat& applied : m_applied) {
            if (applied.end <= start || applied.start >= end)
                continue;
            points.push_back(qMax(applied.start, start));
            points.push_back(qMin(applied.end, end));
        }
        std::sort(points.begin(), points.end());
        points.erase(std::unique(points.begin(), points.end()), points.end());

        for (std::size_t i = 0; i + 1 < points.size(); ++i) {
            const int from = points[i];
            const int to = points[i + 1];
            if (to <= from)
                continue;

            QTextCharFormat format;
            for (const AppliedFormat& applied : m_applied) {
                if (applied.start <= from && applied.end >= to) {
                    format = applied.format;
                    break;
                }
            }
            format.setUnderlineStyle(underline.underlineStyle());
            format.setUnderlineColor(underline.underlineColor());
            QColor tint = underline.underlineColor();
            tint.setAlpha(24);
            format.setBackground(tint);
            setFormat(from, to - from, format);
        }
    }

    const Formats* m_formats;
    std::vector<AppliedFormat> m_applied;
};

LuaHighlighter::LuaHighlighter(QObject* parent)
    : QObject(parent)
    , m_formats(std::make_unique<Formats>()) {
    m_formats->keyword.setForeground(QColor(u"#c792ea"_s));
    m_formats->builtin.setForeground(QColor(u"#82aaff"_s));
    m_formats->string.setForeground(QColor(u"#c3e88d"_s));
    m_formats->number.setForeground(QColor(u"#f78c6c"_s));
    m_formats->comment.setForeground(QColor(u"#7f848e"_s));
    m_formats->comment.setFontItalic(true);

    for (QTextCharFormat* format : { &m_formats->error, &m_formats->warning, &m_formats->info })
        format->setUnderlineStyle(QTextCharFormat::WaveUnderline);
    m_formats->error.setUnderlineColor(QColor(u"#f38ba8"_s));
    m_formats->warning.setUnderlineColor(QColor(u"#e5c07b"_s));
    m_formats->info.setUnderlineColor(QColor(u"#82aaff"_s));
}

LuaHighlighter::~LuaHighlighter() = default;

QQuickTextDocument* LuaHighlighter::textDocument() const {
    return m_document;
}

void LuaHighlighter::setTextDocument(QQuickTextDocument* document) {
    if (m_document == document)
        return;

    m_document = document;
    m_highlighter.reset();

    if (m_document && m_document->textDocument())
        m_highlighter = std::make_unique<Highlighter>(m_document->textDocument(), m_formats.get());

    emit textDocumentChanged();
}

QColor LuaHighlighter::keywordColor() const {
    return m_formats->keyword.foreground().color();
}

void LuaHighlighter::setKeywordColor(const QColor& colour) {
    if (keywordColor() == colour)
        return;
    m_formats->keyword.setForeground(colour);
    if (m_highlighter)
        m_highlighter->rehighlight();
    emit coloursChanged();
}

QColor LuaHighlighter::builtinColor() const {
    return m_formats->builtin.foreground().color();
}

void LuaHighlighter::setBuiltinColor(const QColor& colour) {
    if (builtinColor() == colour)
        return;
    m_formats->builtin.setForeground(colour);
    if (m_highlighter)
        m_highlighter->rehighlight();
    emit coloursChanged();
}

QColor LuaHighlighter::stringColor() const {
    return m_formats->string.foreground().color();
}

void LuaHighlighter::setStringColor(const QColor& colour) {
    if (stringColor() == colour)
        return;
    m_formats->string.setForeground(colour);
    if (m_highlighter)
        m_highlighter->rehighlight();
    emit coloursChanged();
}

QColor LuaHighlighter::numberColor() const {
    return m_formats->number.foreground().color();
}

void LuaHighlighter::setNumberColor(const QColor& colour) {
    if (numberColor() == colour)
        return;
    m_formats->number.setForeground(colour);
    if (m_highlighter)
        m_highlighter->rehighlight();
    emit coloursChanged();
}

QColor LuaHighlighter::commentColor() const {
    return m_formats->comment.foreground().color();
}

void LuaHighlighter::setCommentColor(const QColor& colour) {
    if (commentColor() == colour)
        return;
    m_formats->comment.setForeground(colour);
    if (m_highlighter)
        m_highlighter->rehighlight();
    emit coloursChanged();
}

QColor LuaHighlighter::errorColor() const {
    return m_formats->error.underlineColor();
}

void LuaHighlighter::setErrorColor(const QColor& colour) {
    if (errorColor() == colour)
        return;
    m_formats->error.setUnderlineColor(colour);
    if (m_highlighter)
        m_highlighter->rehighlight();
    emit coloursChanged();
}

QColor LuaHighlighter::warningColor() const {
    return m_formats->warning.underlineColor();
}

void LuaHighlighter::setWarningColor(const QColor& colour) {
    if (warningColor() == colour)
        return;
    m_formats->warning.setUnderlineColor(colour);
    if (m_highlighter)
        m_highlighter->rehighlight();
    emit coloursChanged();
}

QColor LuaHighlighter::infoColor() const {
    return m_formats->info.underlineColor();
}

void LuaHighlighter::setInfoColor(const QColor& colour) {
    if (infoColor() == colour)
        return;
    m_formats->info.setUnderlineColor(colour);
    if (m_highlighter)
        m_highlighter->rehighlight();
    emit coloursChanged();
}

QVariantList LuaHighlighter::diagnostics() const {
    return m_diagnostics;
}

void LuaHighlighter::setDiagnostics(const QVariantList& diagnostics) {
    if (m_diagnostics == diagnostics)
        return;

    m_diagnostics = diagnostics;
    m_formats->diagnostics.clear();
    for (const QVariant& value : diagnostics) {
        const QVariantMap map = value.toMap();
        m_formats->diagnostics.push_back({
            map.value(u"line"_s).toInt(),
            map.value(u"character"_s).toInt(),
            map.value(u"endLine"_s).toInt(),
            map.value(u"endCharacter"_s).toInt(),
            map.value(u"severity"_s, 3).toInt(),
        });
    }

    if (m_highlighter)
        m_highlighter->rehighlight();
    emit diagnosticsChanged();
}

} // namespace aether::shell::editor
