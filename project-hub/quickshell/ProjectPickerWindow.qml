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

    implicitWidth: 520
    implicitHeight: Math.min(720, Math.max(260, panelContent.implicitHeight + 40))
    color: "transparent"

    anchors {
        left: true
        top: true
    }

    property bool isOpen: false
    property bool showWindow: false
    property bool showHidden: false
    property bool loading: false
    property var currentProject: ({ label: "", path: "", infra: ({}) })
    property var projects: []
    property var visibleProjects: []
    property int hiddenProjectCount: 0
    property string errorText: ""

    visible: showWindow

    property real currentTopMargin: isOpen ? 87 : -800

    margins {
        top: root.currentTopMargin
        left: 20
    }

    Behavior on currentTopMargin {
        NumberAnimation {
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
        target: "projects"
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

    function emptyInfra() {
        return {
            name: "",
            state: "stopped",
            state_label: "Stopped",
            summary: "No stack",
            action: "play",
            attention: false,
            services: []
        }
    }

    function projectInfra(project) {
        if (project && project.infra)
            return project.infra
        return emptyInfra()
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

    function projectActionIcon(project) {
        return projectInfra(project).action === "pause" ? "⏸" : "⏵"
    }

    function projectActionTip(project) {
        return projectInfra(project).action === "pause" ? "Stop stack" : "Start stack"
    }

    function updateVisibleProjects() {
        const next = []
        let hiddenCount = 0
        for (const project of projects) {
            if (project.hidden)
                hiddenCount += 1
            if (!project.hidden || showHidden || project.current)
                next.push(project)
        }
        visibleProjects = next
        hiddenProjectCount = hiddenCount
    }

    function refreshState(scan) {
        if (scan === true) {
            if (scanReader.running)
                scanReader.running = false
            loading = true
            scanReader.running = true
            return
        }

        if (stateReader.running)
            stateReader.running = false
        loading = true
        stateReader.running = true
    }

    function runDev(args) {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/dev-project"].concat(args))
    }

    function runControl(args) {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell-containers/scripts/control.sh"].concat(args))
        refreshAfterAction.restart()
        refreshAfterSettle.restart()
    }

    function chooseProject(project) {
        if (!project || !project.id)
            return
        runDev(["set", project.id])
        currentProject = project
        refreshAfterAction.restart()
        refreshAfterSettle.restart()
    }

    function runProjectAction(project) {
        const infra = projectInfra(project)
        const name = infra.name || project.id
        if (!name)
            return
        runControl([infra.action === "pause" ? "stop" : "up", name])
    }

    function runServiceAction(project, service) {
        const infra = projectInfra(project)
        const name = infra.name || project.id
        if (!name || !service || service.protected)
            return
        runControl([service.action === "pause" ? "service-stop" : "service-up", name, service.name])
    }

    function toggleProjectHidden(project) {
        if (!project || !project.id)
            return
        runDev([project.hidden ? "show" : "hide", project.id])
        refreshAfterAction.restart()
        refreshAfterSettle.restart()
    }

    onShowHiddenChanged: updateVisibleProjects()

    Process {
        id: scanReader
        command: [Quickshell.env("HOME") + "/.local/bin/dev-project", "scan", "--quiet"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.refreshState(false)
        }
    }

    Process {
        id: stateReader
        command: [Quickshell.env("HOME") + "/.local/bin/dev-project", "hub-state"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                const output = this.text.trim()
                if (output === "")
                    return
                try {
                    const state = JSON.parse(output)
                    root.currentProject = state.current || ({ label: "", path: "", infra: ({}) })
                    root.projects = state.projects || []
                    root.hiddenProjectCount = state.hidden_count || 0
                    root.updateVisibleProjects()
                    root.errorText = state.error || ""
                } catch (e) {
                    root.errorText = "Could not read project hub state"
                    root.projects = []
                    root.visibleProjects = []
                    console.log("Project Hub state parse failed: " + e)
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
        implicitWidth: 32
        implicitHeight: 32
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

    component ProtectedBadge: Rectangle {
        id: badge
        property string label: "protected"
        visible: label.length > 0
        implicitWidth: badgeText.implicitWidth + 12
        implicitHeight: 20
        radius: 6
        color: Theme.surface_container_high
        border.color: Theme.outline_variant
        border.width: 1

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: badge.label
            color: Theme.tertiary
            font.family: Theme.fontFamily
            font.pixelSize: 10
            verticalAlignment: Text.AlignVCenter
        }
    }

    component HeaderBlock: Rectangle {
        Layout.fillWidth: true
        implicitHeight: 116
        radius: 8
        color: Theme.surface_container
        border.color: Theme.outline_variant
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.currentProject.label || "No project"
                        color: Theme.on_surface
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.currentProject.path || ""
                        color: Theme.on_surface_variant
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        opacity: 0.78
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                }

                StateDot {
                    state: root.projectInfra(root.currentProject).state || "stopped"
                    implicitWidth: 13
                    implicitHeight: 13
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.projectInfra(root.currentProject).summary || ""
                    color: Theme.on_surface_variant
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                ActionIcon {
                    iconTxt: ""
                    tip: "Terminal"
                    onClicked: root.runDev(["terminal"])
                }

                ActionIcon {
                    iconTxt: "󰨞"
                    tip: "VS Code"
                    onClicked: root.runDev(["code"])
                }

                ActionIcon {
                    iconTxt: "󰆍"
                    tip: "Dev drawer"
                    onClicked: root.runDev(["drawer"])
                }

                ActionIcon {
                    iconTxt: "󰕰"
                    tip: "Podman Desktop"
                    onClicked: root.runControl(["desktop"])
                }
            }
        }
    }

    component ServiceRow: Rectangle {
        id: serviceRow
        property var project: ({})
        property var service: ({})

        Layout.fillWidth: true
        implicitHeight: 36
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
                state: serviceRow.service.state || "unknown"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: serviceRow.service.name || ""
                    color: serviceRow.service.protected ? Theme.outline : Theme.on_surface
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: (serviceRow.service.status || "").length > 0
                    text: serviceRow.service.status || ""
                    color: Theme.on_surface_variant
                    opacity: 0.62
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            ProtectedBadge {
                label: serviceRow.service.protected ? (serviceRow.service.protect_reason || "protected") : ""
            }

            Text {
                text: serviceRow.service.state_label || "Unknown"
                color: root.stateColor(serviceRow.service.state || "unknown")
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }

            ActionIcon {
                visible: !serviceRow.service.protected
                implicitWidth: 26
                implicitHeight: 26
                iconTxt: serviceRow.service.action === "pause" ? "⏸" : "⏵"
                tip: serviceRow.service.action === "pause" ? "Stop service" : "Start service"
                onClicked: root.runServiceAction(serviceRow.project, serviceRow.service)
            }
        }
    }

    component ProjectBlock: ColumnLayout {
        id: projectBlock
        property var project: ({})

        Layout.fillWidth: true
        spacing: 4

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            radius: 8
            color: projectMouse.containsMouse ? Theme.surface_container_high : "transparent"
            border.color: projectBlock.project.current === true ? Theme.primary : "transparent"
            border.width: 1
            opacity: projectBlock.project.hidden ? 0.58 : 1

            MouseArea {
                id: projectMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onClicked: root.chooseProject(projectBlock.project)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 9

                StateDot {
                    state: root.projectInfra(projectBlock.project).state
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: projectBlock.project.label || ""
                        color: Theme.on_surface
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.projectInfra(projectBlock.project).summary
                        color: Theme.on_surface_variant
                        opacity: 0.8
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                Text {
                    text: projectBlock.project.current === true ? "current" : (projectBlock.project.kind || "")
                    color: projectBlock.project.current === true ? Theme.primary : Theme.outline
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    opacity: projectBlock.project.current === true ? 1 : 0.82
                }

                ActionIcon {
                    iconTxt: root.projectActionIcon(projectBlock.project)
                    tip: root.projectActionTip(projectBlock.project)
                    onClicked: root.runProjectAction(projectBlock.project)
                }

                ActionIcon {
                    iconTxt: projectBlock.project.hidden ? "" : ""
                    tip: projectBlock.project.hidden ? "Show project" : "Hide project"
                    onClicked: root.toggleProjectHidden(projectBlock.project)
                }
            }
        }

        ColumnLayout {
            visible: projectBlock.project.current === true
            Layout.fillWidth: true
            Layout.leftMargin: 22
            Layout.rightMargin: 4
            spacing: 3

            Text {
                visible: root.projectInfra(projectBlock.project).services.length === 0
                Layout.fillWidth: true
                text: "No services discovered"
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 6
                Layout.bottomMargin: 6
            }

            Repeater {
                model: root.projectInfra(projectBlock.project).services

                ServiceRow {
                    project: projectBlock.project
                    service: modelData
                }
            }
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
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Project Hub"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }

                ActionIcon {
                    iconTxt: root.showHidden ? "" : ""
                    tip: root.showHidden ? "Hide hidden projects" : "Show hidden projects"
                    enabled: root.hiddenProjectCount > 0 || root.showHidden
                    onClicked: root.showHidden = !root.showHidden
                }

                ActionIcon {
                    iconTxt: "󰜉"
                    tip: "Refresh"
                    onClicked: root.refreshState(true)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.primary
                opacity: 0.3
            }

            HeaderBlock {}

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
                visible: !root.errorText && root.visibleProjects.length === 0
                Layout.fillWidth: true
                text: root.loading ? "Loading projects" : "No visible projects"
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 10
                Layout.bottomMargin: 10
            }

            ScrollView {
                id: projectScroll
                visible: root.visibleProjects.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(projectList.implicitHeight, 470)
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    id: projectList
                    width: projectScroll.availableWidth
                    spacing: 8

                    Repeater {
                        model: root.visibleProjects

                        ProjectBlock {
                            project: modelData
                        }
                    }
                }
            }
        }
    }
}
