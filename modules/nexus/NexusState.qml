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
    // back/forward move through it instead of appending again. An entry records the sub-page
    // stack it was left in, so a link that lands on a sub-page is still one step: Back returns to
    // the page and sub-page the user came from, not to the target's own parent page.
    property list<var> pageHistory
    property int historyIndex: -1

    // Sub-pages opened *after* arriving on a page, as opposed to the ones a link arrived with.
    // Only these are unwound one at a time by Back; the rest belong to the history step.
    property int inPageDepth: 0

    // Set while history is being replayed, so the change handlers do not record it again.
    property bool navigatingHistory: false
    readonly property bool canGoBack: historyIndex > 0
    readonly property bool canGoForward: historyIndex >= 0 && historyIndex < pageHistory.length - 1
    property bool searchOpen
    property string searchText
    // About page easter egg: set by holding the logo, cleared by the game when it closes.
    property bool easterEgg: false
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
        inPageDepth++;
        subPageOpened(idx);
    }

    function closeSubPage(): void {
        subPageClosed();
        subPageIdxStack.pop();
        inPageDepth = Math.max(0, inPageDepth - 1);
    }

    // Opens a page (and sub-page) found through search; for a row, its label is
    // highlighted once the page has loaded.
    // Open a top-level page by its stable key (see PageRegistry), optionally pushing one of its
    // sub-pages, and optionally scrolling to and flashing one of its rows. Cross-links use this:
    // a setting lives where the code that owns it lives, and everywhere else that a user would
    // look for it gets a link instead of a second copy.
    function openPageByKey(key: string, sub = 0, row = ""): void {
        for (let i = 0; i < PageRegistry.pages.length; i++) {
            if (PageRegistry.pages[i].key === key) {
                openSearchResult(i, sub, row, row !== "");
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
        // A sub-page opened after arriving is the innermost history: leave it first. A sub-page
        // that came with a link is part of that step and is undone below.
        if (inPageDepth > 0) {
            closeSubPage();
            return;
        }
        if (!canGoBack)
            return;

        historyIndex--;
        restore(pageHistory[historyIndex]);
    }

    function goForward(): void {
        if (!canGoForward)
            return;

        historyIndex++;
        restore(pageHistory[historyIndex]);
    }

    function restore(entry: var): void {
        navigatingHistory = true;
        currentPageIdx = entry.page;
        subPageIdxStack = entry.stack.slice();
        inPageDepth = 0;
        navigatingHistory = false;
    }

    onCurrentPageIdxChanged: {
        // Replaying a history entry sets its own stack right after this.
        if (navigatingHistory)
            return;

        subPageIdxStack.length = 0;
        inPageDepth = 0;

        // Already pointing at this entry because back/forward moved here.
        if (historyIndex >= 0 && pageHistory[historyIndex].page === currentPageIdx)
            return;

        // A new destination drops the entries that were ahead of it.
        pageHistory = pageHistory.slice(0, historyIndex + 1);
        pageHistory.push({
            page: currentPageIdx,
            stack: []
        });
        historyIndex = pageHistory.length - 1;
    }

    // Keeps the entry being shown in step with the sub-page the user has open, so leaving the
    // page and coming back restores what was actually on screen.
    onSubPageIdxStackChanged: {
        if (navigatingHistory || historyIndex < 0)
            return;
        pageHistory[historyIndex].stack = subPageIdxStack.slice();
    }

    Component.onCompleted: {
        // `currentPageIdx` may still be at its default when the window binds a starting page, in
        // which case no change signal ever arrived to seed the history.
        if (pageHistory.length === 0) {
            pageHistory = [
                {
                    page: currentPageIdx,
                    stack: []
                }
            ];
            historyIndex = 0;
        }
    }
}
