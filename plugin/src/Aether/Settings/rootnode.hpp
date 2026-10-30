#pragma once

#include "common.hpp"
#include "objectnode.hpp"
#include "settingsfile.hpp"

namespace aether::shell::settings {

class RootNode : public ObjectNode {
    Q_OBJECT

    Q_PROPERTY(QList<aether::shell::settings::Diagnostic> diagnostics READ diagnostics NOTIFY diagnosticsChanged)

public:
    explicit RootNode(bool watch, const QString& path, RootNode* fallback, QObject* parent = nullptr);

    [[nodiscard]] QList<Diagnostic> diagnostics() const;

    void load();

    // Explicit save for QML callers; writes are otherwise auto-saved via the
    // change batcher.
    Q_INVOKABLE void save();

signals:
    void diagnosticsChanged();
    void treeLoaded(aether::shell::settings::RootNode* self);
    void treeLoadFailed(aether::shell::settings::RootNode* self, const QString& error);
    void treeSaveFailed(aether::shell::settings::RootNode* self, const QString& error);

private:
    SettingsFile* const m_file;
    QList<Diagnostic> m_diagnostics;

    void reloadFromFile();
    void saveToFile();
};

} // namespace aether::shell::settings
