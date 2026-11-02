pragma Singleton

import QtQuick
import Quickshell
import Aether.Config
import Aether.I18n
import qs.components
import qs.services
import qs.modules.nexus

Singleton {
    id: root

    // The most recently created settings window, while it lives. Windows null this on
    // destruction, so it is never a dangling pointer.
    property var current: null

    function create(parent: Item, props: var): void {
        root.current = nexusComp.createObject(parent ?? dummy, props);
    }

    // Open the settings at a given page, reusing the window that is already open rather
    // than stacking another one on top of it -- which is what a settings window should do,
    // and what stops sixteen of them piling up.
    function openPage(page: int): void {
        if (root.current)
            root.current.openPage(page);
        else
            root.create(null, {
                page
            });
    }

    QtObject {
        id: dummy
    }

    Component {
        id: nexusComp

        FloatingWindow {
            id: win

            // Which settings page to land on. Set through WindowFactory.create()'s props,
            // which is how the `nexus openPage` IPC call reaches it.
            property int page: 0

            // `page` only seeds the initial page: nState's binding to it breaks on the first
            // navigation, so a later openPage() has to address the state directly.
            function openPage(p: int): void {
                nexus.nState.currentPageIdx = p;
            }

            color: Colours.tPalette.m3surface

            surfaceFormat.opaque: false

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            Component.onDestruction: {
                if (WindowFactory.current === win)
                    WindowFactory.current = null;
            }

            implicitWidth: nexus.implicitWidth

            implicitHeight: nexus.implicitHeight

            minimumSize.width: contentItem.Tokens.sizes.nexus.minWidth

            minimumSize.height: contentItem.Tokens.sizes.nexus.minHeight

            contentItem.Config.screen: screen.name

            contentItem.Tokens.screen: screen.name

            title: Tr.tr("Nexus — %1").arg(PageRegistry.pages[nexus.nState.currentPageIdx]?.label ?? "")

            // The size follows the screen, but the compositor only reads the implicit size when the
            // window is created. When the screen changes (e.g. a new display scale), resize and
            // re-centre the window ourselves.
            Connections {
                function onImplicitWidthChanged(): void {
                    resizeTimer.restart();
                }

                function onImplicitHeightChanged(): void {
                    resizeTimer.restart();
                }

                target: nexus
            }

            Timer {
                id: resizeTimer

                interval: 150

                onTriggered: {
                    // Hyprland has to be told which window; match this one by its title
                    const toplevel = Hypr.toplevels.values.find(t => t.title === win.title);
                    if (!toplevel)
                        return;
                    const addr = toplevel.address.startsWith("0x") ? toplevel.address : `0x${toplevel.address}`;
                    const w = Math.round(nexus.implicitWidth);
                    const h = Math.round(nexus.implicitHeight);
                    if (Hypr.usingLua) {
                        Hypr.dispatch(`hl.dsp.window.resize({ x = ${w}, y = ${h}, exact = true, window = "address:${addr}" })`);
                        Hypr.dispatch(`hl.dsp.window.center({ window = "address:${addr}" })`);
                    } else {
                        Hypr.dispatch(`resizewindowpixel exact ${w} ${h},address:${addr}`);
                        Hypr.dispatch(`centerwindow`);
                    }
                }
            }

            Nexus {
                id: nexus

                anchors.fill: parent

                nState.screen: win.screen

                nState.isWindow: true

                nState.currentPageIdx: win.page

                onClose: win.destroy()
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
