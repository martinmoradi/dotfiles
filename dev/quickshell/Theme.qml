pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string fontFamily: "Fira Sans Semibold"

    property color background: "#121318"
    property color error: "#ffb4ab"
    property color on_background: "#e2e2e9"
    property color on_surface: "#e2e2e9"
    property color on_surface_variant: "#c5c6d0"
    property color outline: "#8f9099"
    property color outline_variant: "#44464f"
    property color primary: "#b0c6ff"
    property color primary_container: "#2e4578"
    property color secondary: "#c0c6dc"
    property color surface: "#121318"
    property color surface_container: "#1e1f25"
    property color surface_container_high: "#282a2f"
    property color tertiary: "#e0bbde"

    readonly property color healthy: "#8bd99c"

    property var themeReader: Process {
        id: reader
        command: ["cat", Quickshell.env("HOME") + "/.config/ml4w/colors/colors.json"]

        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim()
                if (output === "")
                    return

                try {
                    const newColors = JSON.parse(output)
                    for (const key in newColors) {
                        if (root.hasOwnProperty(key) && key !== "objectName")
                            root[key] = newColors[key]
                    }
                } catch (e) {
                    console.log("Project Picker theme parse failed: " + e)
                }
            }
        }
    }

    function reloadTheme() {
        reader.running = false
        reader.running = true
    }

    Component.onCompleted: reloadTheme()
}
