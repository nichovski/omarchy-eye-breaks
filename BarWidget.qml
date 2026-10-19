import QtQuick
import qs.Commons
import qs.Ui

// Bar button: eye plus minutes until the next eye break. Click pauses or resumes.
BarWidget {
  id: root
  moduleName: "nichovski.eye-breaks"

  readonly property var service: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property bool available: !!service
  readonly property bool paused: available && service.paused === true
  readonly property int minutesLeft: available ? Math.ceil(service.secondsLeft / 60) : 0

  // Nerd Font glyphs: nf-md-eye and nf-md-eye_off.
  readonly property string glyph: String.fromCodePoint(paused ? 0xF0209 : 0xF0208)
  readonly property string label: !available ? "" : paused ? "off" : minutesLeft + "m"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical || root.label === "" ? root.glyph : root.glyph + " " + root.label
    active: root.available && root.service.breakOpen === true
    dimmed: !root.available || root.paused
    horizontalMargin: 8.5
    tooltipText: !root.available ? "Eye breaks unavailable"
      : root.paused ? "Eye breaks paused - click to resume"
      : "Next eye break in " + root.minutesLeft + " min - click to pause"

    onPressed: function(b) {
      if (b === Qt.LeftButton && root.available) root.service.paused = !root.service.paused
    }
  }
}
