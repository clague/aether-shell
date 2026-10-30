#pragma once

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace aether::shell::config {

class DashboardPerformance : public settings::ObjectNode {
    CONFIG_NODE(DashboardPerformance, settings::ObjectNode)

    CONFIG_PROPERTY(bool, showBattery, true)
    CONFIG_PROPERTY(bool, showGpu, true)
    CONFIG_PROPERTY(bool, showCpu, true)
    CONFIG_PROPERTY(bool, showMemory, true)
    CONFIG_PROPERTY(bool, showStorage, true)
    CONFIG_PROPERTY(bool, showNetwork, true)
};

class DashboardPomodoro : public settings::ObjectNode {
    CONFIG_NODE(DashboardPomodoro, settings::ObjectNode)

    CONFIG_PROPERTY(int, focusDuration, 25)
    CONFIG_PROPERTY(int, shortBreakDuration, 5)
    CONFIG_PROPERTY(int, longBreakDuration, 15)
    CONFIG_PROPERTY(int, sessionsBeforeLongBreak, 4)
    CONFIG_PROPERTY(bool, defaultToPomodoro, true)
};

class DashboardConfig : public settings::ObjectNode {
    CONFIG_NODE(DashboardConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showOnHover, true)
    CONFIG_PROPERTY(bool, showDashboard, true)
    CONFIG_PROPERTY(bool, showMedia, true)
    CONFIG_PROPERTY(bool, showPerformance, true)
    CONFIG_PROPERTY(bool, showWeather, true)
    CONFIG_PROPERTY(bool, showWeatherLocation, true)
    CONFIG_PROPERTY(bool, showTerminal, true)
    CONFIG_PROPERTY(bool, showHyprlandSplash, false)
    CONFIG_PROPERTY(bool, colorizeMediaGif, true)
    CONFIG_PROPERTY(bool, useMediaShapes, false)
    CONFIG_PROPERTY(bool, randomizeMediaShapeColors, true)
    CONFIG_PROPERTY(bool, syncMediaShapesToBeat, false)
    CONFIG_PROPERTY(bool, replaceMediaLyricsWithVisuals, false)
    CONFIG_GLOBAL_PROPERTY(int, profilePicShape, 9)
    CONFIG_PROPERTY(bool, showClockSeconds, false)
    CONFIG_GLOBAL_PROPERTY(int, mediaUpdateInterval, 500)
    CONFIG_GLOBAL_PROPERTY(int, resourceUpdateInterval, 1000)
    CONFIG_PROPERTY(int, dragThreshold, 50)
    CONFIG_SUBOBJECT(DashboardPerformance, performance)
    CONFIG_SUBOBJECT(DashboardPomodoro, pomodoro)
};

} // namespace aether::shell::config
