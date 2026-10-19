import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string pluginId: "nichovski.eye-breaks"

  property bool opened: false
  property int seconds: 20
  property bool water: false
  property real startMs: 0
  property int remaining: 0

  function open(payloadJson) {
    var payload = {}
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = {} }
    root.seconds = payload.seconds > 0 ? payload.seconds : 20
    root.water = payload.water === true
    root.startMs = Date.now()
    root.remaining = root.seconds
    root.opened = true
  }

  // shell.hide() calls this too, so every way out reports to the service once.
  function close() {
    if (!root.opened) return
    root.opened = false
    var service = root.shell ? root.shell.serviceFor(root.pluginId) : null
    if (service) service.finish()
    if (root.shell) root.shell.hide(root.pluginId)
  }

  Timer {
    interval: 250
    repeat: true
    running: root.opened
    onTriggered: {
      root.remaining = Math.max(0, root.seconds - Math.floor((Date.now() - root.startMs) / 1000))
      if (root.remaining === 0) root.close()
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData
      readonly property bool primary: modelData === Quickshell.screens[0]
      readonly property real u: Math.min(width, height) / 100

      screen: modelData
      visible: root.opened
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      WlrLayershell.namespace: "eye-breaks"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      function takeFocus() {
        if (visible) Qt.callLater(function() { keyCatcher.forceActiveFocus() })
      }
      onVisibleChanged: takeFocus()
      onPrimaryChanged: takeFocus()
      Component.onCompleted: takeFocus()

      Rectangle {
        anchors.fill: parent
        color: Util.alpha(Color.background, 0.9)
      }

      MouseArea {
        anchors.fill: parent
      }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
          }
        }
      }

      Column {
        anchors.centerIn: parent
        spacing: panel.u * 3

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.remaining
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: panel.u * 16
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Look at something 6 m away and blink"
          color: Color.menu.text
          font.family: Style.font.family
          font.pixelSize: panel.u * 3.5
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          visible: root.water
          text: "Drink some water"
          color: Color.menu.text
          opacity: 0.85
          font.family: Style.font.family
          font.pixelSize: panel.u * 3
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Relax your shoulders. Esc to skip"
          color: Color.menu.text
          opacity: 0.55
          font.family: Style.font.family
          font.pixelSize: panel.u * 1.8
        }
      }
    }
  }
}
