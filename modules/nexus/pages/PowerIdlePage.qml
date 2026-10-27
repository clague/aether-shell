pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    function getTimeout(action: string, defaultSec: int): int {
        const list = GlobalConfig.general.idle.timeouts;
        for (let i = 0; i < list.length; i++) {
            const item = list[i];
            if (item.idleAction === action)
                return item.timeout;
            if (Array.isArray(item.idleAction) && item.idleAction.includes(action))
                return item.timeout;
        }
        return defaultSec;
    }

    function updateTimeout(action: string, seconds: int, returnAct: string): void {
        const list = JSON.parse(JSON.stringify(GlobalConfig.general.idle.timeouts));
        let found = false;
        for (let i = 0; i < list.length; i++) {
            if (list[i].idleAction === action || (Array.isArray(list[i].idleAction) && list[i].idleAction.includes(action))) {
                list[i].timeout = seconds;
                found = true;
                break;
            }
        }
        if (!found) {
            const entry = {
                "idleAction": action,
                "timeout": seconds
            };
            if (returnAct)
                entry.returnAction = returnAct;
            list.push(entry);
        }
        GlobalConfig.general.idle.timeouts = list;
    }

    title: Tr.tr("Power & idle")

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Battery
        SectionHeader {
            first: true
            text: Tr.tr("Battery management")
        }

        StepperRow {
            first: true
            last: true
            label: Tr.tr("Critical hibernate level")
            subtext: Tr.tr("Battery percentage that triggers automatic hibernation (%)")
            value: GlobalConfig.general.battery.criticalLevel
            from: 1
            to: 15
            stepSize: 1
            onMoved: v => GlobalConfig.general.battery.criticalLevel = v
        }

        // Idle & Sleep
        SectionHeader {
            text: Tr.tr("Idle & Sleep")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Inhibit sleep during audio")
            subtext: Tr.tr("Keep system awake while media or music is playing")
            checked: GlobalConfig.general.idle.inhibitWhenAudio
            onToggled: GlobalConfig.general.idle.inhibitWhenAudio = checked
        }

        ToggleRow {
            text: Tr.tr("Inhibit sleep when plugged in")
            subtext: Tr.tr("Keep system awake while charging on AC power")
            checked: GlobalConfig.general.idle.inhibitWhenCharging
            onToggled: GlobalConfig.general.idle.inhibitWhenCharging = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Lock before sleep")
            subtext: Tr.tr("Automatically lock the session before system suspends")
            checked: GlobalConfig.general.idle.lockBeforeSleep
            onToggled: GlobalConfig.general.idle.lockBeforeSleep = checked
        }

        // Timeouts
        SectionHeader {
            text: Tr.tr("Inactivity timeouts")
        }

        StepperRow {
            first: true
            label: Tr.tr("Lock screen timeout")
            subtext: Tr.tr("Minutes of inactivity before locking the screen")
            value: Math.round(root.getTimeout("lock", 180) / 60)
            from: 1
            to: 60
            stepSize: 1
            onMoved: v => root.updateTimeout("lock", v * 60, "")
        }

        StepperRow {
            label: Tr.tr("Display turn-off (DPMS)")
            subtext: Tr.tr("Minutes of inactivity before turning displays off")
            value: Math.round(root.getTimeout("dpms off", 300) / 60)
            from: 1
            to: 120
            stepSize: 1
            onMoved: v => root.updateTimeout("dpms off", v * 60, "dpms on")
        }

        StepperRow {
            last: true
            label: Tr.tr("Suspend / Hibernate timeout")
            subtext: Tr.tr("Minutes of inactivity before putting system to sleep")
            value: Math.round(root.getTimeout("suspendThenHibernate", 600) / 60)
            from: 2
            to: 240
            stepSize: 2
            onMoved: v => root.updateTimeout("suspendThenHibernate", v * 60, "")
        }
    }
}
