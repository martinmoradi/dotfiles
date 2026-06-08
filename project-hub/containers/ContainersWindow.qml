import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore

    implicitWidth: 430
    implicitHeight: Math.min(620, Math.max(150, panelContent.implicitHeight + 40))
    color: "transparent"

    anchors {
        right: true
        top: true
    }

    property bool isOpen: false
    property bool showWindow: false
    property bool loading: false
    property var projects: []
    property string errorText: ""
    property var expandedProjects: ({})

    visible: showWindow

    property real currentTopMargin: isOpen ? 87 : -800

    margins {
        top: root.currentTopMargin
        right: 20
    }

    Behavior on currentTopMargin {
        NumberAnimation {
            id: slideAnim
            duration: 350
            easing.type: Easing.OutQuint

            onRunningChanged: {
                if (!running && !root.isOpen)
                    root.showWindow = false
            }
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.isOpen && root.showWindow
        onCleared: {
            if (root.isOpen)
                root.isOpen = false
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.isOpen)
                root.isOpen = false
        }
    }

    IpcHandler {
        target: "containers"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
    }

    onIsOpenChanged: {
        if (isOpen) {
            showWindow = true
            Theme.reloadTheme()
            refreshState()
        }
    }

    function stateColor(state) {
        if (state === "healthy" || state === "running")
            return Theme.healthy
        if (state === "starting" || state === "partial")
            return Theme.tertiary
        if (state === "trouble" || state === "crashed" || state === "unhealthy" || state === "unknown")
            return Theme.error
        return Theme.outline
    }

    function projectExpanded(project) {
        return project.attention || expandedProjects[project.name] === true
    }

    function toggleProject(project) {
        let next = Object.assign({}, expandedProjects)
        next[project.name] = !projectExpanded(project)
        expandedProjects = next
    }

    function refreshState() {
        if (stateReader.running)
            stateReader.running = false
        loading = true
        stateReader.running = true
    }

    function runControl(args) {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell-containers/scripts/control.sh"].concat(args))
        refreshAfterAction.restart()
        refreshAfterSettle.restart()
    }

    Process {
        id: stateReader
        command: [Quickshell.env("HOME") + "/.config/quickshell-containers/scripts/state.sh"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                try {
                    const state = JSON.parse(this.text.trim())
                    root.errorText = state.error || ""
                    root.projects = state.projects || []
                } catch (e) {
                    root.errorText = "Could not read dev stack state"
                    root.projects = []
                    console.log("Dev Stacks state parse failed: " + e)
                }
            }
        }
    }

    Timer {
        interval: 2500
        repeat: true
        running: root.showWindow
        onTriggered: root.refreshState()
    }

    Timer {
        id: refreshAfterAction
        interval: 900
        repeat: false
        onTriggered: root.refreshState()
    }

    Timer {
        id: refreshAfterSettle
        interval: 2600
        repeat: false
        onTriggered: root.refreshState()
    }

    component ActionIcon: Button {
        id: action
        property string iconTxt: ""
        property string tip: ""
        implicitWidth: 30
        implicitHeight: 30
        text: iconTxt
        font.family: "monospace"

        background: Rectangle {
            color: action.hovered ? Theme.primary_container : "transparent"
            border.color: action.hovered ? Theme.primary : "transparent"
            border.width: 1
            radius: 8
        }

        contentItem: Text {
            text: action.text
            color: action.enabled ? Theme.primary : Theme.outline
            opacity: action.enabled ? 1 : 0.55
            font.family: "monospace"
            font.pixelSize: 17
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        ToolTip.visible: action.hovered && action.tip.length > 0
        ToolTip.text: action.tip
    }

    component StateDot: Rectangle {
        id: dot
        property string state: "stopped"
        // implicit size so QtQuick Layouts give the dot real width (a bare
        // Rectangle has implicitWidth 0 and collapses inside a RowLayout).
        implicitWidth: 11
        implicitHeight: 11
        Layout.alignment: Qt.AlignVCenter
        radius: width / 2
        color: root.stateColor(state)
        opacity: state === "starting" ? 0.65 : 1

        Behavior on color { ColorAnimation { duration: 250 } }

        SequentialAnimation on opacity {
            running: dot.state === "starting"
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 650; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 0.95; duration: 650; easing.type: Easing.InOutQuad }
        }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            border.color: Theme.primary
            border.width: 2
            radius: 10
            opacity: 0.95
        }

        ColumnLayout {
            id: panelContent
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "󰡨"
                    color: Theme.primary
                    font.family: "monospace"
                    font.pixelSize: 20
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: "Dev Stacks"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }

                ActionIcon {
                    iconTxt: "󰜉"
                    tip: "Refresh"
                    onClicked: root.refreshState()
                }

                ActionIcon {
                    iconTxt: "󰕰"
                    tip: "Podman Desktop"
                    onClicked: root.runControl(["desktop"])
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.primary
                opacity: 0.3
            }

            Text {
                visible: root.errorText.length > 0
                Layout.fillWidth: true
                text: root.errorText
                color: Theme.error
                font.family: Theme.fontFamily
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Text {
                visible: !root.errorText && root.projects.length === 0
                Layout.fillWidth: true
                text: root.loading ? "Checking dev stacks" : "No dev stacks running"
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 14
                Layout.bottomMargin: 14
            }

            ScrollView {
                id: projectScroll
                visible: root.projects.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(projectList.implicitHeight, 500)
                clip: true
                // Pin content to the visible width and disable sideways scroll —
                // otherwise the inner layout has no defined width and collapses.
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    id: projectList
                    width: projectScroll.availableWidth
                    spacing: 8

                    Repeater {
                        model: root.projects

                        ColumnLayout {
                            id: projectBlock
                            Layout.fillWidth: true
                            spacing: 4
                            property var project: modelData
                            property bool expanded: root.projectExpanded(project)

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 46
                                radius: 8
                                color: projectMouse.containsMouse ? Theme.surface_container_high : "transparent"
                                border.color: projectBlock.expanded ? Theme.outline_variant : "transparent"
                                border.width: 1

                                MouseArea {
                                    id: projectMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    onClicked: root.toggleProject(projectBlock.project)
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 8
                                    spacing: 9

                                    Text {
                                        text: projectBlock.expanded ? "󰅀" : "󰅂"
                                        color: Theme.primary
                                        font.family: "monospace"
                                        font.pixelSize: 14
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    StateDot { state: projectBlock.project.state }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            Layout.fillWidth: true
                                            text: projectBlock.project.name
                                            color: Theme.on_surface
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 14
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: projectBlock.project.summary
                                            color: Theme.on_surface_variant
                                            opacity: 0.8
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }

                                    ActionIcon {
                                        iconTxt: projectBlock.project.action === "pause" ? "⏸" : "⏵"
                                        tip: projectBlock.project.action === "pause" ? "Pause stack" : "Start stack"
                                        onClicked: {
                                            root.runControl([projectBlock.project.action === "pause" ? "stop" : "up", projectBlock.project.name])
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                visible: projectBlock.expanded
                                Layout.fillWidth: true
                                Layout.leftMargin: 34
                                Layout.rightMargin: 4
                                spacing: 3

                                Repeater {
                                    model: projectBlock.project.services

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 34
                                        radius: 6
                                        color: serviceMouse.containsMouse ? Theme.surface_container : "transparent"

                                        MouseArea {
                                            id: serviceMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 6
                                            spacing: 8

                                            StateDot {
                                                implicitWidth: 8
                                                implicitHeight: 8
                                                state: modelData.state
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.name
                                                color: modelData.protected ? Theme.outline : Theme.on_surface
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                visible: modelData.protected
                                                text: modelData.protect_reason
                                                color: Theme.tertiary
                                                opacity: 0.85
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                            }

                                            Text {
                                                text: modelData.state_label
                                                color: root.stateColor(modelData.state)
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                            }

                                            ActionIcon {
                                                visible: !modelData.protected
                                                implicitWidth: 26
                                                implicitHeight: 26
                                                iconTxt: modelData.action === "pause" ? "⏸" : "⏵"
                                                tip: modelData.action === "pause" ? "Pause service" : "Start service"
                                                onClicked: {
                                                    root.runControl([modelData.action === "pause" ? "service-stop" : "service-up", projectBlock.project.name, modelData.name])
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
