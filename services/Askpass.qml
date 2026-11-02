pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Aether.I18n

// Password prompts for programs that have no terminal to ask on -- SSH_ASKPASS and SUDO_ASKPASS.
// scripts/askpass.sh is the helper: it starts a request here, then polls for the answer and prints
// it. The dialog lives in modules/polkit/AskpassDialog.qml.
//
// One request is shown at a time, oldest first. Answers are kept until the helper collects them
// (or they age out, for a helper that was killed while the dialog was still up).
Singleton {
    id: root

    readonly property var current: queue.length > 0 ? queue[0] : null
    readonly property bool active: current !== null

    property var queue: []

    // id -> { value, at }
    property var answers: ({})

    // A password left in here is a password on disk in the worst case, so drop anything the
    // helper never came back for.
    readonly property int answerTtlMs: 60000

    function request(prompt: string): string {
        const id = `${Date.now().toString(36)}${Math.floor(Math.random() * 1679616).toString(36)}`;
        purgeExpired();
        queue = queue.concat([
            {
                id,
                prompt: prompt.trim().length > 0 ? prompt.trim() : Tr.tr("Password required")
            }
        ]);
        return id;
    }

    function poll(id: string): string {
        purgeExpired();
        const answer = answers[id];
        if (answer === undefined)
            return queue.some(r => r.id === id) ? "pending" : "unknown";
        deleteAnswer(id);
        return answer.value;
    }

    function submit(text: string): void {
        finish(`ok:${text}`);
    }

    function cancel(): void {
        finish("cancel");
    }

    function cancelRequest(id: string): void {
        if (current && current.id === id)
            finish("cancel");
    }

    function finish(value: string): void {
        if (!current)
            return;
        const id = current.id;
        queue = queue.slice(1);
        const next = Object.assign({}, answers);
        next[id] = {
            value,
            at: Date.now()
        };
        answers = next;
    }

    function deleteAnswer(id: string): void {
        if (answers[id] === undefined)
            return;
        const next = Object.assign({}, answers);
        delete next[id];
        answers = next;
    }

    function purgeExpired(): void {
        const now = Date.now();
        let stale = false;
        const next = {};
        for (const key in answers) {
            if (now - answers[key].at > answerTtlMs) {
                stale = true;
                continue;
            }
            next[key] = answers[key];
        }
        if (stale)
            answers = next;
    }

    // A helper that was killed leaves its request current forever; no one is polling it and the
    // dialog has no other way to go away.
    onCurrentChanged: requestTimeout.restart()

    Timer {
        id: requestTimeout

        interval: 120000
        running: root.active
        onTriggered: root.cancel()
    }

    IpcHandler {
        // Returns the request id; poll() with it until the answer is not "pending".
        function request(prompt: string): string {
            return root.request(prompt);
        }

        // "pending" | "unknown" | "cancel" | "ok:<password>"
        function poll(id: string): string {
            return root.poll(id);
        }

        function cancel(id: string): void {
            root.cancelRequest(id);
        }

        // Cancels whatever is on screen, for a caller that does not know the id.
        function cancelCurrent(): void {
            root.cancel();
        }

        target: "askpass"
    }
}
