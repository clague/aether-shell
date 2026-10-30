#include "borderconfig.hpp"

#include <algorithm>

namespace aether::shell::config {

int BorderConfig::minThickness() {
    return 2;
}

int BorderConfig::clampedThickness() const {
    return std::max(minThickness(), m_thickness);
}

} // namespace aether::shell::config
