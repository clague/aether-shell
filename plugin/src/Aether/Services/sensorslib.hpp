#pragma once

#include <optional>

namespace aether::shell::services::sensorslib {

void ensureInit();

[[nodiscard]] std::optional<double> cpuPackageTemp();
[[nodiscard]] std::optional<double> gpuPciAverageTemp();

} // namespace aether::shell::services::sensorslib
