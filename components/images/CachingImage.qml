import QtQuick
import Quickshell
import Aether.Images

Image {
    id: root

    property string path

    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    // A width of 0 means the item has not been laid out yet. The provider treats 0x0 as
    // "no constraint" and hands back the original file, which for a 7680x4320 wallpaper is
    // a 130MB decode held until the sized request replaces it. Wait for a real size.
    source: (path && width > 0 && height > 0) ? IUtils.urlForPath(path, fillMode) : ""
    sourceSize: {
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        return Qt.size(Math.max(1, width * dpr), Math.max(1, height * dpr));
    }
}
