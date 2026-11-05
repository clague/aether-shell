#include "luahighlighter.hpp"

#include <qtextdocument.h>
#include <qtextformat.h>

namespace aether::shell::editor {

using Qt::StringLiterals::operator""_s;

namespace {

const QSet<QString>& keywords() {
    static const QSet<QString> k_luaKeywords = {
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
    return k_luaKeywords;
}

const QSet<QString>& builtins() {
    static const QSet<QString> k_luaBuiltins = {
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
    return k_luaBuiltins;
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
    return static_cast<int>(text.indexOf(u']' + QString(level, u'=') + u']', from));
}

constexpr int k_stringStateBase = 1;    // 1 + level
constexpr int k_commentStateBase = 101; // 101 + level
constexpr int k_maxLevel = 20;

} // namespace

class LuaHighlighter::Formats {
public:
    QTextCharFormat keyword;
    QTextCharFormat builtin;
    QTextCharFormat string;
    QTextCharFormat number;
    QTextCharFormat comment;
};

class LuaHighlighter::Highlighter : public QSyntaxHighlighter {
public:
    Highlighter(QTextDocument* document, const Formats* formats)
        : QSyntaxHighlighter(document)
        , m_formats(formats) {}

protected:
    void highlightBlock(const QString& text) override {
        const int n = static_cast<int>(text.size());
        int i = 0;
        if (continueLongBlock(text, i, n))
            return;

        setCurrentBlockState(0);

        while (i < n) {
            const int next = highlightToken(text, i, n);
            if (next < 0)
                return;
            i = next;
        }
    }

private:
    // A long string or comment that started on a previous line. Returns true when the block is
    // still inside it, so the caller does not scan for other tokens.
    bool continueLongBlock(const QString& text, int& i, int n) {
        const int state = previousBlockState();
        const bool isString = state >= k_stringStateBase && state <= k_stringStateBase + k_maxLevel;
        const bool isComment = state >= k_commentStateBase && state <= k_commentStateBase + k_maxLevel;
        if (!isString && !isComment)
            return false;

        const int level = state - (isString ? k_stringStateBase : k_commentStateBase);
        const int end = findLongClose(text, 0, level);
        const int closeLength = level + 2;
        const QTextCharFormat& format = isString ? m_formats->string : m_formats->comment;
        if (end < 0) {
            setFormat(0, n, format);
            setCurrentBlockState(state);
            return true;
        }

        setFormat(0, end + closeLength, format);
        i = end + closeLength;
        return false;
    }

    // Returns the next position to look at, or -1 when the rest of the block is consumed.
    int highlightToken(const QString& text, int i, int n) {
        const QChar c = text[i];
        if (c == u'-' && i + 1 < n && text[i + 1] == u'-')
            return highlightComment(text, i, n);
        if (c == u'[') {
            const int next = highlightLongString(text, i, n);
            if (next != i)
                return next;
        }
        if (c == u'"' || c == u'\'')
            return highlightQuotedString(text, i, n);
        if (c.isDigit() || (c == u'.' && i + 1 < n && text[i + 1].isDigit()))
            return highlightNumber(text, i, n);
        if (c.isLetter() || c == u'_')
            return highlightWord(text, i, n);
        return i + 1;
    }

    int highlightComment(const QString& text, int i, int n) {
        int level = 0;
        int length = 0;
        if (!longBracket(text, i + 2, level, length)) {
            setFormat(i, n - i, m_formats->comment);
            return -1;
        }

        const int end = findLongClose(text, i + 2 + length, level);
        const int closeLength = level + 2;
        if (end < 0) {
            setFormat(i, n - i, m_formats->comment);
            setCurrentBlockState(k_commentStateBase + qMin(level, k_maxLevel));
            return -1;
        }

        setFormat(i, end + closeLength - i, m_formats->comment);
        return end + closeLength;
    }

    int highlightLongString(const QString& text, int i, int n) {
        int level = 0;
        int length = 0;
        if (!longBracket(text, i, level, length))
            return i;

        const int end = findLongClose(text, i + length, level);
        const int closeLength = level + 2;
        if (end < 0) {
            setFormat(i, n - i, m_formats->string);
            setCurrentBlockState(k_stringStateBase + qMin(level, k_maxLevel));
            return -1;
        }

        setFormat(i, end + closeLength - i, m_formats->string);
        return end + closeLength;
    }

    int highlightQuotedString(const QString& text, int i, int n) {
        const QChar quote = text[i];
        int j = i + 1;
        while (j < n) {
            if (text[j] == u'\\') {
                j += 2;
                continue;
            }
            if (text[j] == quote) {
                ++j;
                break;
            }
            ++j;
        }

        setFormat(i, qMin(j, n) - i, m_formats->string);
        return j;
    }

    int highlightNumber(const QString& text, int i, int n) {
        int j = i;
        while (j < n && (text[j].isLetterOrNumber() || text[j] == u'.' || text[j] == u'_'))
            ++j;
        setFormat(i, j - i, m_formats->number);
        return j;
    }

    int highlightWord(const QString& text, int i, int n) {
        int j = i;
        while (j < n && (text[j].isLetterOrNumber() || text[j] == u'_'))
            ++j;

        const QString word = text.mid(i, j - i);
        if (keywords().contains(word))
            setFormat(i, j - i, m_formats->keyword);
        else if (builtins().contains(word))
            setFormat(i, j - i, m_formats->builtin);
        return j;
    }

    const Formats* m_formats;
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

} // namespace aether::shell::editor
