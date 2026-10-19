import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar button: eye plus minutes until the next eye break. Click pauses or resumes.
// Reads the status file the service writes: replacement bars (like the
// menubar manager) give widgets no access to the service object.
BarWidget {
  id: root
  moduleName: "nichovski.eye-breaks"

  property var status: null
  // Pause state asked for by a click, shown until the service confirms it (IPC can be slow).
  property var pendingPaused: null

  readonly property bool available: status !== null
  readonly property bool paused: pendingPaused !== null ? pendingPaused : available && status.paused === true
  readonly property int minutesLeft: available ? status.minutesLeft : 0

  // Nerd Font glyphs: nf-md-eye and nf-md-eye_off.
  readonly property string glyph: String.fromCodePoint(paused ? 0xF0209 : 0xF0208)
  readonly property string label: !available ? "" : paused ? "off" : minutesLeft + "m"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function readStatus() {
    var parsed = null
    try { parsed = JSON.parse(statusFile.text() || "null") } catch (e) { parsed = null }
    root.status = parsed
    if (parsed && parsed.paused === root.pendingPaused) root.pendingPaused = null
  }

  FileView {
    id: statusFile
    path: Quickshell.env("HOME") + "/.local/state/eye-breaks/status.json"
    printErrors: false
    onLoaded: root.readStatus()
    onLoadFailed: root.status = null
  }

  // The service replaces the file on each write, which drops a file watch, so poll.
  Timer {
    interval: 5000
    repeat: true
    running: true
    onTriggered: statusFile.reload()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical || root.label === "" ? root.glyph : root.glyph + " " + root.label
    active: root.available && root.status.breakOpen === true
    dimmed: !root.available || root.paused
    horizontalMargin: 8.5
    tooltipText: !root.available ? "Eye breaks unavailable"
      : root.paused ? "Eye breaks paused - click to resume"
      : "Next eye break in " + root.minutesLeft + " min - click to pause"

    onPressed: function(b) {
      if (b !== Qt.LeftButton || !root.available) return
      var next = !root.paused
      root.pendingPaused = next
      Quickshell.execDetached(["omarchy-shell", "eyes", next ? "pause" : "resume"])
    }
  }
}
