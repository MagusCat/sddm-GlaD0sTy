import QtQuick 2.15
import QtQuick.Window 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: cfg("background", "#0a0a0a")

    // Everything user-tunable lives in theme.conf
    function cfg(key, fallback) { return text(key) || fallback }
    // QSettings splits unquoted values at commas; glue them back
    function text(key) { const v = config[key]; return typeof v === "string" ? v : Array.from(v || []).join(", ") }
    function pool(name) { return config.keys().filter(k => k.startsWith("GLaDOS/" + name)).map(text).filter(q => q) }

    readonly property real s: Math.min(width / 1920, height / 1080)
    readonly property color accent: cfg("accent", "#d4953d")
    readonly property color alert: cfg("alert", "#ff3333")
    readonly property color highlight: cfg("highlight", "#ffcc99")
    readonly property bool effects: cfg("effects", "true") !== "false"
    readonly property string mono: cfg("font", pixelFont.name)

    property int sessionIndex: sessionModel.lastIndex
    readonly property string sessionName: sessions.count > sessionIndex ? sessions.itemAt(sessionIndex).name : ""
    property string status: "awaiting credentials"
    property bool failed: false
    property string line: ""   // what GLaDOS is saying
    property int typed: 0      // how much of it is on screen
    property var leaving: null // sddm.powerOff / sddm.reboot, run once the farewell is typed

    readonly property var quotes: ({ greet: pool("greet"), idle: pool("idle"), login: pool("login"), fail: pool("fail"), bye: pool("bye") })

    function say(lines) {
        line = lines[Math.floor(Math.random() * lines.length)] || ""
        typed = 0
        typer.restart()
        chatter.restart()
    }

    function farewell(action) {
        if (leaving) return
        leaving = action
        say(quotes.bye)
        chatter.stop() // after say(), which restarts it
    }

    Timer {
        id: typer
        interval: Number(cfg("typeSpeed", "90")); repeat: true
        onTriggered: {
            if (typed < line.length) return typed++
            stop()
            if (leaving) switchOff.start()
        }
    }

    // Random remark every 20-45 s of silence
    Timer {
        id: chatter
        interval: 30000; repeat: true; running: true
        onTriggered: { interval = 20000 + Math.random() * 25000; say(quotes.idle) }
    }

    FontLoader { id: pixelFont; source: "assets/Dot.ttf" }

    // Session names aren't exposed by index, so mirror them here
    Repeater { id: sessions; model: sessionModel; Item { readonly property string name: model.name } }

    function login() {
        failed = false
        status = "authenticating..."
        say(quotes.login)
        sddm.login(username.text, password.text, sessionIndex)
    }

    function glitchNow() {
        glitch.jolt = (Math.random() - 0.5) * 60 * s
        glitch.restart()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            failed = true
            status = "ACCESS DENIED"
            say(quotes.fail)
            password.text = ""
            password.forceActiveFocus()
            glitchNow()
        }
    }

    Component {
        id: blockCursor
        Rectangle {
            width: root.s * 16
            color: root.accent
            visible: parent.activeFocus
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                PropertyAction { value: 1 }
                PauseAnimation { duration: 530 }
                PropertyAction { value: 0 }
                PauseAnimation { duration: 530 }
            }
        }
    }

    // Everything on the "tube": shaken by glitches, squashed on power-on
    Item {
        id: crt
        width: parent.width
        height: parent.height
        transform: Scale { id: tube; origin.x: crt.width / 2; origin.y: crt.height / 2 }

        Image {
            anchors.fill: parent
            source: cfg("backgroundImage", "assets/background.png")
            fillMode: Image.PreserveAspectCrop
        }

        Item {
            id: ui
            anchors.fill: parent
            layer.enabled: root.effects
            layer.effect: Glow { radius: 6; samples: 13; spread: 0; color: root.accent; transparentBorder: true }

            Column {
                id: term
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 190 * root.s // pushes the block (glados image + form) below the background title
                width: 640 * root.s
                spacing: 10 * root.s

                Text {
                    text: "APERTURE SCIENCE // GLaDOS v1.09"
                    color: root.accent; opacity: 0.6
                    font.family: root.mono; font.pixelSize: 24 * root.s
                }

                Rectangle { width: parent.width; height: Math.max(1, 2 * root.s); color: root.accent; opacity: 0.4 }

                Row {
                    spacing: 14 * root.s
                    Text { id: userLabel; text: "login:"; color: root.accent; font.family: root.mono; font.pixelSize: 30 * root.s }
                    TextInput {
                        id: username
                        width: term.width - userLabel.width - parent.spacing
                        text: userModel.lastUser
                        color: root.accent
                        font: userLabel.font
                        selectionColor: root.accent
                        selectedTextColor: root.color
                        selectByMouse: true
                        activeFocusOnTab: true
                        cursorDelegate: blockCursor
                        KeyNavigation.tab: password
                        onAccepted: password.forceActiveFocus()
                    }
                }

                Row {
                    spacing: 14 * root.s
                    Text { id: passLabel; text: "password:"; color: root.accent; font.family: root.mono; font.pixelSize: 30 * root.s }
                    TextInput {
                        id: password
                        width: term.width - passLabel.width - parent.spacing
                        echoMode: TextInput.Password
                        passwordCharacter: "*"
                        color: root.accent
                        font: passLabel.font
                        selectionColor: root.accent
                        selectedTextColor: root.color
                        activeFocusOnTab: true
                        cursorDelegate: blockCursor
                        KeyNavigation.backtab: username
                        onAccepted: root.login()
                    }
                }

                Text {
                    text: "> " + root.status
                    color: root.failed ? root.alert : root.accent
                    opacity: root.failed ? 1 : 0.6
                    font.family: root.mono; font.pixelSize: 24 * root.s
                }

                Text {
                    width: parent.width
                    height: font.pixelSize * 2.6 // room for two lines so the form doesn't jump
                    wrapMode: Text.WordWrap
                    text: "GLaDOS: " + root.line.slice(0, root.typed) + (root.typed % 2 || !typer.running ? "_" : "")
                    color: root.accent; opacity: 0.85
                    font.family: root.mono; font.pixelSize: 24 * root.s
                }
            }

            Row {
                anchors { left: parent.left; bottom: parent.bottom; margins: 28 * root.s }
                spacing: 40 * root.s

                Repeater {
                    model: [
                        { key: "F1", label: "session: " + root.sessionName, run: () => root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, sessions.count) },
                        { key: "F2", label: "reboot", run: () => root.farewell(() => sddm.reboot()) },
                        { key: "F3", label: "shutdown", run: () => root.farewell(() => sddm.powerOff()) }
                    ]
                    Text {
                        text: "[" + modelData.key + "] " + modelData.label
                        color: hover.containsMouse ? root.highlight : root.accent
                        opacity: hover.containsMouse ? 1 : 0.7
                        font.family: root.mono; font.pixelSize: 24 * root.s
                        Shortcut { sequence: modelData.key; onActivated: modelData.run() }
                        MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.run() }
                    }
                }
            }
        }

        // Outside `ui` so it gets no glow
        Image {
            source: cfg("gladosImage", "assets/glados.png")
            width: 300 * root.s
            height: width
            fillMode: Image.PreserveAspectFit
            x: (parent.width - width) / 2
            y: term.y - height - term.spacing
        }
    }

    // --- CRT overlays (on top, never take input) ---

    Canvas {
        id: scanlines
        anchors.fill: parent
        visible: root.effects
        enabled: false
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = "rgba(0, 0, 0, 0.35)"
            for (var y = 0; y < height; y += 4) ctx.fillRect(0, y, width, 2)
        }
    }

    // Slow bright band rolling down the tube
    Rectangle {
        visible: root.effects
        width: parent.width
        height: 160 * root.s
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.06) }
            GradientStop { position: 1.0; color: "transparent" }
        }
        NumberAnimation on y { running: root.effects; from: -160 * root.s; to: root.height; duration: 8000; loops: Animation.Infinite }
    }

    RadialGradient {
        anchors.fill: parent
        visible: root.effects
        horizontalRadius: width * 0.75
        verticalRadius: height * 0.75
        gradient: Gradient {
            GradientStop { position: 0.55; color: "transparent" }
            GradientStop { position: 1.0; color: "#e6000000" }
        }
    }

    Rectangle {
        id: flicker
        anchors.fill: parent
        color: "black"
        opacity: 0
        enabled: false
        Timer {
            interval: 90; running: root.effects; repeat: true
            onTriggered: flicker.opacity = Math.random() * 0.05
        }
    }

    // --- Glitch: random horizontal jolt of the whole tube ---

    Timer {
        interval: 3000; running: root.effects; repeat: true
        onTriggered: { interval = 2000 + Math.random() * 5000; root.glitchNow() }
    }

    SequentialAnimation {
        id: glitch
        property real jolt: 0
        PropertyAction { target: crt; property: "opacity"; value: 0.8 }
        NumberAnimation { target: crt; property: "x"; to: glitch.jolt; duration: 40 }
        NumberAnimation { target: crt; property: "x"; to: 0; duration: 30 }
        PropertyAction { target: crt; property: "opacity"; value: 1 }
    }

    // --- Power-on: collapse to a line, then open vertically ---

    SequentialAnimation {
        running: root.effects
        PropertyAction { target: tube; properties: "xScale,yScale"; value: 0.004 }
        NumberAnimation { target: tube; property: "xScale"; to: 1; duration: 220; easing.type: Easing.OutQuad }
        NumberAnimation { target: tube; property: "yScale"; to: 1; duration: 320; easing.type: Easing.OutExpo }
    }

    // --- Power-off: let the farewell sink in, then collapse the tube to a dot ---

    SequentialAnimation {
        id: switchOff
        PauseAnimation { duration: 1500 }
        NumberAnimation { target: tube; property: "yScale"; to: 0.004; duration: 250; easing.type: Easing.InExpo }
        NumberAnimation { target: tube; property: "xScale"; to: 0; duration: 200; easing.type: Easing.InQuad }
        ScriptAction { script: root.leaving() }
    }

    Component.onCompleted: {
        (username.text ? password : username).forceActiveFocus()
        say(quotes.greet)
    }
}
