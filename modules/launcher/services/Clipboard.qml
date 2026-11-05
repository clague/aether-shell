pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Aether.Config

QtObject {
    id: root

    property var items: []

    readonly property string imageCacheDir: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/caelestia/clipboard`

    property Process fetcher: Process {
        running: false
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                const lines = text.trim().split("\n");

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (!line)
                        continue;

                    const match = line.match(/^(\d+)\t(.+)/);
                    if (!match)
                        continue;

                    result.push({
                        id: parseInt(match[1]),
                        preview: match[2],
                        isImage: /^\[\[ binary data \d+ KiB png \d+x\d+ \]\]/.test(match[2])
                    });
                }

                root.items = result;
            }
        }
    }

    function reload(): void {
        fetcher.running = true;
    }

    function getSortedItems(): var {
        if (!items.length)
            return [];
        const favClips = new Set((GlobalConfig.launcher.favouriteClips || []).map(String));
        const favs = [];
        const rest = [];
        for (const item of items) {
            if (favClips.has(String(item.id))) {
                favs.push(item);
            } else {
                rest.push(item);
            }
        }
        return [...favs, ...rest];
    }

    function getImagePath(clipId: int): string {
        return imageCacheDir + "/" + clipId + ".png";
    }

    function ensureImageCached(id: int): void {
        // The delegate asks once when it is built; a file already decoded by an earlier open
        // is reused instead of spawning cliphist again.
        const imgPath = getImagePath(id);
        Quickshell.execDetached(["sh", "-c", 'test -f "$1" || { mkdir -p "$2" && cliphist decode "$3" > "$1"; }', "sh", imgPath, imageCacheDir, String(id)]);
    }
}
