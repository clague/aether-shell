import "navpane"
import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus

ColumnLayout {
    id: root

    required property NexusState nState

    // Focuses the sidebar row of the given page, used when the left arrow leaves the settings
    // pane. Falls back to the first focusable control (the search field) if the row is hidden.
    function focusPageRow(page: int): bool {
        if (locations.focusPageRow(page))
            return true;
        return FocusNav.focusFirstIn(root);
    }

    spacing: Tokens.spacing.large

    SearchBar {
        id: searchField

        z: 3

        activeFocusOnTab: true

        Layout.fillWidth: true

        placeholderText: Tr.tr("Search settings")

        font: Tokens.font.body.large

        bg.color: Colours.tPalette.m3surfaceContainerLowest

        bg.border.color: Colours.palette.m3outlineVariant

        searchIcon.fontStyle: Tokens.font.icon.medium

        searchIcon.anchors.leftMargin: Tokens.padding.largeIncreased

        clearIcon.font: Tokens.font.icon.medium

        clearIcon.padding: Tokens.padding.extraSmall

        // While results are showing the arrows walk the result list; otherwise leave the key
        // unhandled so the window's focus traversal can move to the next control.
        Keys.onDownPressed: event => {
            if (!root.nState.searchOpen) {
                event.accepted = false;
                return;
            }
            root.nState.searchMove(1);
        }

        Keys.onUpPressed: event => {
            if (!root.nState.searchOpen) {
                event.accepted = false;
                return;
            }
            root.nState.searchMove(-1);
        }

        Keys.onReturnPressed: root.nState.searchActivate()

        Keys.onEnterPressed: root.nState.searchActivate()

        Keys.onEscapePressed: event => {
            if (text.length > 0)
                clear();
            else
                event.accepted = false;
        }

        Behavior on bg.border.color {
            CAnim {}
        }

        Binding {
            target: root.nState

            property: "searchOpen"

            value: searchField.text.length > 0
        }

        Binding {
            target: root.nState

            property: "searchText"

            value: searchField.text
        }

        Connections {
            function onFocusSearch(): void {
                searchField.forceActiveFocus();
                searchField.selectAll();
            }

            function onClearSearch(): void {
                searchField.clear();
            }

            target: root.nState
        }
    }

    MonitorTargetSelector {
        z: 2

        Layout.fillWidth: true

        nState: root.nState
    }

    NavLocations {
        id: locations

        z: 1

        Layout.fillWidth: true

        Layout.fillHeight: true

        Layout.topMargin: -topMargin

        Layout.bottomMargin: -bottomMargin

        nState: root.nState
    }
}
