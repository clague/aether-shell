#include "common.hpp"

#include <qstandardpaths.h>

namespace aether::shell::state {

using Qt::StringLiterals::operator""_s;

Q_LOGGING_CATEGORY(lcState, "aether.state", QtInfoMsg)

QString stateDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericStateLocation) + u"/caelestia"_s;
}

QString monitorStateDir() {
    return stateDir() + u"/monitors"_s;
}

QString runtimeDir() {
    return QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation) + u"/caelestia"_s;
}

QString monitorRuntimeDir() {
    return runtimeDir() + u"/monitors"_s;
}

} // namespace aether::shell::state
