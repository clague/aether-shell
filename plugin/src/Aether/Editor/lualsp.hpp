#pragma once

#include <qjsonobject.h>
#include <qjsonvalue.h>
#include <qjsonarray.h>
#include <qobject.h>
#include <qprocess.h>
#include <qqmlintegration.h>
#include <qvariant.h>

#include <memory>

namespace aether::shell::editor {

// A very small LSP client for lua-language-server, scoped to what the config editor needs:
// diagnostics for the open file and completion at the cursor. The server is started with stdio
// (its default transport) and the document is synchronised with full-text changes, which is
// cheap for a config file and avoids incremental-edit bookkeeping.
class LuaLsp : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString filePath READ filePath WRITE setFilePath NOTIFY filePathChanged)
    // off | starting | ready | error | unavailable
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QVariantList diagnostics READ diagnostics NOTIFY diagnosticsChanged)
    Q_PROPERTY(QVariantList completions READ completions NOTIFY completionsChanged)

public:
    explicit LuaLsp(QObject* parent = nullptr);
    ~LuaLsp() override;

    [[nodiscard]] QString filePath() const;
    void setFilePath(const QString& path);

    [[nodiscard]] QString status() const;
    [[nodiscard]] QVariantList diagnostics() const;
    [[nodiscard]] QVariantList completions() const;

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void open(const QString& text);
    Q_INVOKABLE void sync(const QString& text);
    Q_INVOKABLE void requestCompletion(int line, int character);

signals:
    void filePathChanged();
    void statusChanged();
    void diagnosticsChanged();
    void completionsChanged();

private:
    void setStatus(const QString& status);
    void send(const QJsonObject& message);
    void notify(const QString& method, const QJsonObject& params);
    void onData();
    void dispatch(const QJsonObject& message);
    void sendInitialized();
    void parseDiagnostics(const QJsonObject& params);
    void parseCompletion(const QJsonValue& result);

    QProcess m_process;
    QString m_filePath;
    QString m_status = QStringLiteral("off");
    QString m_uri;
    QByteArray m_buffer;
    QString m_text;
    int m_version = 0;
    int m_nextId = 1;
    int m_initializeId = -1;
    int m_completionId = -1;
    bool m_open = false;
    QVariantList m_diagnostics;
    QVariantList m_completions;
};

} // namespace aether::shell::editor
