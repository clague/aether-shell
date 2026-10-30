pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    function getTimeout(action: string, defaultSec: int): int {
        const list = GlobalConfig.general.idle.timeouts;
        for (let i = 0; i < list.values.length; i++) {
            const item = list.values[i];
            if (item.idleAction === action)
                return item.timeout;
            if (Array.isArray(item.idleAction) && item.idleAction.includes(action))
                return item.timeout;
        }
        return defaultSec;
    }

    // The settings schema moved to typed lists; the write surface is the node's
    // remove/insert pair rather than whole-list assignment.
    function updateTimeout(action: string, seconds: int, returnAct: string): void {
        const list = GlobalConfig.general.idle.timeouts;
        let found = false;
        for (let i = 0; i < list.values.length; i++) {
            const item = list.values[i];
            if (item.idleAction === action || (Array.isArray(item.idleAction) && item.idleAction.includes(action))) {
                const at = Object.assign({}, item, {
                    idleAction: item.idleAction,
                    timeout: seconds
                });
                if (returnAct)
                    at.returnAction = returnAct;
                else
                    delete at.returnAction;
                list.remove(i);
                list.insert(at, i);
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
            list.insert(entry);
        }
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
