#pragma once

#include <qloggingcategory.h>
#include <qstring.h>

namespace aether::shell::config {

Q_DECLARE_LOGGING_CATEGORY(lcConfig)

QString configDir();
QString monitorConfigDir();

} // namespace aether::shell::config
