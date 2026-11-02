import QtQuick
import Quickshell

AnimatedImage {
    id: root

    property string path

    asynchronous: true
    fillMode: AnimatedImage.PreserveAspectCrop
    // Without this an animated wallpaper is decoded at its file resolution, frame by frame:
    // a 7680x4320 GIF is 130MB per frame. Ask for the size it is actually drawn at.
    sourceSize: {
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        return Qt.size(Math.max(1, width * dpr), Math.max(1, height * dpr));
    }
    source: path || ""
    playing: true

    onSourceChanged: playing = true
}
