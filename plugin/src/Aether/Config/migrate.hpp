#pragma once

#include <qstring.h>

namespace aether::shell::config {

// Moves the old top-level "hybrid" block to "aether" before the config loads.
//
// A one-time backup is written next to the file, because the rewrite removes the old key:
// a downgrade to a build that still reads "hybrid" would otherwise lose every feature flag
// and variant. Returns false when there is nothing to do or the backup/commit failed.
bool migrateLegacyFeatureBlock(const QString& path);

} // namespace aether::shell::config
