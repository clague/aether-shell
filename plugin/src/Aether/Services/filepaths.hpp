#pragma once

#include <qstring.h>

namespace aether::services {

// A path inside `directory` that nothing occupies yet: "photo.jpg", then "photo (1).jpg", and so
// on. A transfer that lands on an existing name would otherwise truncate the file already there.
[[nodiscard]] QString uniquePath(const QString& directory, const QString& fileName);

} // namespace aether::services
