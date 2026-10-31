import QtQuick
import Quickshell
import Quickshell.Bluetooth

QtObject {
    property ShellScreen screen
    property bool isWindow
    property bool animatingContainer
    property int currentPageIdx
    property list<int> subPageIdxStack
    // Top-level page history, browser style: `historyIndex` is the entry being shown, so
    // back/forward move through it instead of appending again.
    property list<int> pageHistory
    property int historyIndex: -1
    readonly property bool canGoBack: historyIndex > 0
    readonly property bool canGoForward: historyIndex >= 0 && historyIndex < pageHistory.length - 1
    property bool searchOpen
    property string searchText
    // Label of the row to scroll to and flash once its page has loaded
    property string pendingHighlight
    property bool justUnlockedDevMode: false
    property string targetScreen: ""

    property string selectedWallpaperCategory
    property string wallpaperFilterType: "all"
    property BluetoothDevice selectedBtDevice
    property DesktopEntry selectedApp
    property int editingVpnIndex: -1
    property string selectedNetworkSsid
    property string selectedEthernetInterface
    property bool networkDetailsFromSaved

    signal close
    signal focusSearch
    signal clearSearch
    signal searchMove(int delta)
    signal searchActivate
    signal subPageOpened(idx: int)
    signal subPageClosed

    function openSubPage(idx: int): void {
        subPageIdxStack.push(idx);
        subPageOpened(idx);
    }

    function closeSubPage(): void {
        subPageClosed();
        subPageIdxStack.pop();
    }

    // Opens a page (and sub-page) found through search; for a row, its label is
    // highlighted once the page has loaded.
    // Open a top-level page by its stable key (see PageRegistry), optionally pushing one of
    // its sub-pages. Used by cross-links such as Apps -> Hyprland keybind apps.
    function openPageByKey(key: string, sub = 0): void {
        for (let i = 0; i < PageRegistry.pages.length; i++) {
            if (PageRegistry.pages[i].key === key) {
                openSearchResult(i, sub, "", false);
                return;
            }
        }
    }

    function openSearchResult(page: int, sub: int, label: string, isRow: bool): void {
        clearSearch();
        pendingHighlight = isRow ? label : "";

        if (currentPageIdx === page) {
            while (subPageIdxStack.length > 0)
                closeSubPage();
            if (sub > 0)
                openSubPage(sub);
        } else {
            currentPageIdx = page; // also resets the sub-page stack
            if (sub > 0)
                subPageIdxStack = [sub];
        }
    }

    function goBack(): void {
        // A sub-page is the innermost history: leave it before changing the top-level page.
        if (subPageIdxStack.length > 0) {
            closeSubPage();
            return;
        }
        if (!canGoBack)
            return;

        historyIndex--;
        currentPageIdx = pageHistory[historyIndex];
    }

    function goForward(): void {
        if (!canGoForward)
            return;

        historyIndex++;
        currentPageIdx = pageHistory[historyIndex];
    }

    onCurrentPageIdxChanged: {
        subPageIdxStack.length = 0;

        // Already pointing at this entry because back/forward moved here.
        if (historyIndex >= 0 && pageHistory[historyIndex] === currentPageIdx)
            return;

        // A new destination drops the entries that were ahead of it.
        pageHistory = pageHistory.slice(0, historyIndex + 1);
        pageHistory.push(currentPageIdx);
        historyIndex = pageHistory.length - 1;
    }

    Component.onCompleted: {
        // `currentPageIdx` may still be at its default when the window binds a starting page, in
        // which case no change signal ever arrived to seed the history.
        if (pageHistory.length === 0) {
            pageHistory = [currentPageIdx];
            historyIndex = 0;
        }
    }
}
