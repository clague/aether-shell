#include "lualsp.hpp"

#include <qdir.h>
#include <qfileinfo.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qloggingcategory.h>
#include <qstandardpaths.h>
#include <qurl.h>

#include <utility>

namespace aether::shell::editor {

using Qt::StringLiterals::operator""_s;

namespace {

Q_LOGGING_CATEGORY(lcLsp, "aether.editor.lsp", QtInfoMsg)

QVariantMap diagnosticMap(const QJsonObject& diagnostic) {
    const QJsonObject range = diagnostic.value(u"range"_s).toObject();
    const QJsonObject start = range.value(u"start"_s).toObject();
    const QJsonObject end = range.value(u"end"_s).toObject();

    return {
        {u"line"_s, start.value(u"line"_s).toInt()},
        {u"character"_s, start.value(u"character"_s).toInt()},
        {u"endLine"_s, end.value(u"line"_s).toInt()},
        {u"endCharacter"_s, end.value(u"character"_s).toInt()},
        {u"severity"_s, diagnostic.value(u"severity"_s).toInt(3)},
        {u"message"_s, diagnostic.value(u"message"_s).toString()},
        {u"source"_s, diagnostic.value(u"source"_s).toString()},
    };
}

QJsonObject luaSettings() {
    return {
        { u"runtime"_s, QJsonObject{ { u"version"_s, u"Lua 5.4"_s } } },
        { u"workspace"_s,
            QJsonObject{ { u"library"_s, QJsonArray{ (QDir::homePath() + u"/.config/hypr"_s) } } } },
        { u"diagnostics"_s,
            QJsonObject{ { u"globals"_s, QJsonArray{ u"hl"_s, u"vars"_s } } } },
    };
}

QJsonObject wrappedSettings() {
    return { { u"Lua"_s, luaSettings() } };
}

} // namespace

LuaLsp::LuaLsp(QObject* parent)
    : QObject(parent) {
    m_process.setProcessChannelMode(QProcess::SeparateChannels);

    QObject::connect(&m_process, &QProcess::readyReadStandardOutput, this, &LuaLsp::onData);
    QObject::connect(&m_process, &QProcess::readyReadStandardError, this, [this] {
        const QByteArray error = m_process.readAllStandardError();
        if (!error.isEmpty())
            qCDebug(lcLsp).noquote() << error.trimmed();
    });
    QObject::connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart)
            setStatus(u"unavailable"_s);
        else {
            qCWarning(lcLsp) << "lua-language-server error" << error;
            setStatus(u"error"_s);
        }
    });
    QObject::connect(&m_process, &QProcess::finished, this, [this](int code, QProcess::ExitStatus) {
        m_open = false;
        if (m_status != u"off"_s && m_status != u"unavailable"_s)
            setStatus(code == 0 ? u"off"_s : u"error"_s);
    });
}

LuaLsp::~LuaLsp() {
    stop();
}

QString LuaLsp::filePath() const {
    return m_filePath;
}

void LuaLsp::setFilePath(const QString& path) {
    if (m_filePath == path)
        return;

    if (m_open && !m_uri.isEmpty())
        notify(u"textDocument/didClose"_s, { { u"textDocument"_s, QJsonObject{ { u"uri"_s, m_uri } } } });

    m_filePath = path;
    m_uri = path.isEmpty() ? QString() : QUrl::fromLocalFile(path).toString();
    m_open = false;
    m_text.clear();
    m_version = 0;
    emit filePathChanged();

    if (m_status == u"ready"_s && !m_text.isEmpty())
        open(m_text);
}

QString LuaLsp::status() const {
    return m_status;
}

QVariantList LuaLsp::diagnostics() const {
    return m_diagnostics;
}

QVariantList LuaLsp::completions() const {
    return m_completions;
}

void LuaLsp::setStatus(const QString& status) {
    if (m_status == status)
        return;
    m_status = status;
    emit statusChanged();
}

void LuaLsp::start() {
    if (m_process.state() != QProcess::NotRunning)
        return;

    if (QStandardPaths::findExecutable(u"lua-language-server"_s).isEmpty()) {
        setStatus(u"unavailable"_s);
        return;
    }

    m_buffer.clear();
    m_open = false;
    m_version = 0;
    m_diagnostics.clear();
    m_completions.clear();
    emit diagnosticsChanged();
    emit completionsChanged();
    setStatus(u"starting"_s);

    m_process.setProgram(u"lua-language-server"_s);
    m_process.setArguments({});
    m_process.start();

    m_initializeId = m_nextId++;
    const QString root = m_filePath.isEmpty() ? QDir::homePath() : QFileInfo(m_filePath).absolutePath();
    const QString rootUri = QUrl::fromLocalFile(root).toString();

    send({
        { u"jsonrpc"_s, u"2.0"_s },
        { u"id"_s, m_initializeId },
        { u"method"_s, u"initialize"_s },
        { u"params"_s,
            QJsonObject{
                { u"processId"_s, QJsonValue::Null },
                { u"clientInfo"_s, QJsonObject{ { u"name"_s, u"aether"_s } } },
                { u"rootUri"_s, rootUri },
                { u"workspaceFolders"_s,
                    QJsonArray{ QJsonObject{ { u"uri"_s, rootUri }, { u"name"_s, u"caelestia"_s } } } },
                { u"capabilities"_s,
                    QJsonObject{
                        { u"textDocument"_s,
                            QJsonObject{
                                { u"publishDiagnostics"_s, QJsonObject{} },
                                { u"completion"_s,
                                    QJsonObject{ { u"completionItem"_s,
                                        QJsonObject{ { u"snippetSupport"_s, false } } } } },
                            } },
                        { u"workspace"_s, QJsonObject{ { u"configuration"_s, true } } },
                    } },
                { u"initializationOptions"_s, wrappedSettings() },
            } },
    });
}

void LuaLsp::stop() {
    if (m_process.state() == QProcess::NotRunning) {
        setStatus(u"off"_s);
        return;
    }

    m_process.terminate();
    if (!m_process.waitForFinished(800)) {
        m_process.kill();
        m_process.waitForFinished(500);
    }
    m_open = false;
    setStatus(u"off"_s);
}

void LuaLsp::open(const QString& text) {
    m_text = text;
    m_version = 1;

    if (m_status != u"ready"_s || m_uri.isEmpty())
        return;

    notify(u"textDocument/didOpen"_s,
        {
            { u"textDocument"_s,
                QJsonObject{
                    { u"uri"_s, m_uri },
                    { u"languageId"_s, u"lua"_s },
                    { u"version"_s, m_version },
                    { u"text"_s, text },
                } },
        });
    m_open = true;
}

void LuaLsp::sync(const QString& text) {
    m_text = text;
    if (!m_open)
        return;

    notify(u"textDocument/didChange"_s,
        {
            { u"textDocument"_s, QJsonObject{ { u"uri"_s, m_uri }, { u"version"_s, ++m_version } } },
            { u"contentChanges"_s, QJsonArray{ QJsonObject{ { u"text"_s, text } } } },
        });
}

void LuaLsp::requestCompletion(int line, int character) {
    if (m_status != u"ready"_s || !m_open)
        return;

    m_completionId = m_nextId++;
    send({
        { u"jsonrpc"_s, u"2.0"_s },
        { u"id"_s, m_completionId },
        { u"method"_s, u"textDocument/completion"_s },
        { u"params"_s,
            QJsonObject{
                { u"textDocument"_s, QJsonObject{ { u"uri"_s, m_uri } } },
                { u"position"_s, QJsonObject{ { u"line"_s, line }, { u"character"_s, character } } },
                { u"context"_s, QJsonObject{ { u"triggerKind"_s, 1 } } },
            } },
    });
}

void LuaLsp::send(const QJsonObject& message) {
    if (m_process.state() == QProcess::NotRunning)
        return;

    const QByteArray body = QJsonDocument(message).toJson(QJsonDocument::Compact);
    QByteArray frame = "Content-Length: " + QByteArray::number(body.size()) + "\r\n\r\n";
    frame.append(body);
    m_process.write(frame);
    m_process.waitForBytesWritten(200);
}

void LuaLsp::notify(const QString& method, const QJsonObject& params) {
    send({
        { u"jsonrpc"_s, u"2.0"_s },
        { u"method"_s, method },
        { u"params"_s, params },
    });
}

void LuaLsp::onData() {
    m_buffer.append(m_process.readAllStandardOutput());

    while (true) {
        const int headerEnd = m_buffer.indexOf("\r\n\r\n");
        if (headerEnd < 0)
            return;

        int contentLength = -1;
        const QByteArray header = m_buffer.left(headerEnd);
        for (const QByteArray& line : header.split('\n')) {
            const QByteArray trimmed = line.trimmed();
            if (trimmed.startsWith("Content-Length:"))
                contentLength = trimmed.mid(static_cast<int>(qstrlen("Content-Length:"))).trimmed().toInt();
        }

        if (contentLength < 0) {
            m_buffer.remove(0, headerEnd + 4);
            continue;
        }

        const int total = headerEnd + 4 + contentLength;
        if (m_buffer.size() < total)
            return;

        const QByteArray body = m_buffer.mid(headerEnd + 4, contentLength);
        m_buffer.remove(0, total);

        const QJsonObject message = QJsonDocument::fromJson(body).object();
        if (!message.isEmpty())
            dispatch(message);
    }
}

void LuaLsp::dispatch(const QJsonObject& message) {
    const QString method = message.value(u"method"_s).toString();

    if (!method.isEmpty()) {
        if (method == u"workspace/configuration"_s) {
            const int requestId = message.value(u"id"_s).toInt(-1);
            if (requestId >= 0) {
                QJsonArray result;
                for (int i = 0; i < message.value(u"params"_s).toObject().value(u"items"_s).toArray().size(); i++)
                    result.append(wrappedSettings());
                send({ { u"jsonrpc"_s, u"2.0"_s }, { u"id"_s, requestId }, { u"result"_s, result } });
            }
            return;
        }
        if (method == u"textDocument/publishDiagnostics"_s) {
            parseDiagnostics(message.value(u"params"_s).toObject());
        } else if (method == u"window/showMessage"_s) {
            qCInfo(lcLsp).noquote() << message.value(u"params"_s).toObject().value(u"message"_s).toString();
        }
        return;
    }

    const int id = message.value(u"id"_s).toInt(-1);

    if (id == m_initializeId) {
        if (message.contains(u"error"_s)) {
            setStatus(u"error"_s);
            return;
        }
        setStatus(u"ready"_s);
        send({ { u"jsonrpc"_s, u"2.0"_s }, { u"method"_s, u"initialized"_s }, { u"params"_s, QJsonObject{} } });
        notify(u"workspace/didChangeConfiguration"_s, { { u"settings"_s, wrappedSettings() } });
        if (!m_text.isEmpty())
            open(m_text);
        return;
    }

    if (id == m_completionId) {
        m_completionId = -1;
        parseCompletion(message.value(u"result"_s));
    }
}

void LuaLsp::parseDiagnostics(const QJsonObject& params) {
    if (params.value(u"uri"_s).toString() != m_uri)
        return;

    QVariantList list;
    for (const QJsonValue& value : params.value(u"diagnostics"_s).toArray()) {
        const QJsonObject diagnostic = value.toObject();
        // Hyprland injects these as globals, but lua-language-server insists on seeing them
        // in its own config (which it ignores from us in this build). They are not errors.
        const QString message = diagnostic.value(u"message"_s).toString();
        if (message.startsWith(u"Undefined global"_s)
            && (message.contains(u"`hl`"_s) || message.contains(u"`vars`"_s) || message.contains(u"`scheme`"_s)
                || message.contains(u"'hl'"_s) || message.contains(u"'vars'"_s) || message.contains(u"'scheme'"_s)))
            continue;

        list.append(diagnosticMap(diagnostic));
    }

    m_diagnostics = list;
    emit diagnosticsChanged();
}

void LuaLsp::parseCompletion(const QJsonValue& result) {
    QJsonArray items;
    if (result.isArray())
        items = result.toArray();
    else if (result.isObject())
        items = result.toObject().value(u"items"_s).toArray();

    QVariantList list;
    list.reserve(qMin(items.size(), 200));

    for (const QJsonValue& value : items) {
        if (list.size() >= 200)
            break;

        const QJsonObject item = value.toObject();
        const QJsonObject textEdit = item.value(u"textEdit"_s).toObject();
        QString insert = textEdit.value(u"newText"_s).toString();
        if (insert.isEmpty())
            insert = item.value(u"insertText"_s).toString();
        if (insert.isEmpty())
            insert = item.value(u"label"_s).toString();

        list.append(QVariantMap{
            { u"label"_s, item.value(u"label"_s).toString() },
            { u"detail"_s, item.value(u"detail"_s).toString() },
            { u"insert"_s, insert },
            { u"kind"_s, item.value(u"kind"_s).toInt() },
        });
    }

    m_completions = list;
    emit completionsChanged();
}

} // namespace aether::shell::editor
