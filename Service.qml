import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
  id: root

  // Injected by omarchy-shell's service loader.
  property var shell: null

  readonly property string pluginId: "nichovski.eye-breaks"
  readonly property int workSeconds: 20 * 60
  readonly property int breakSeconds: 20
  // Every third eye break (about once an hour) also asks for water.
  readonly property int waterEvery: 3
  readonly property int tickSeconds: 5

  // Seconds of screen use since the last break. Idle time counts as a rest.
  property int activeSeconds: 0
  property int breaksDone: 0
  property bool paused: false
  property bool breakOpen: false
  property real openedAtMs: 0

  readonly property int secondsLeft: Math.max(0, workSeconds - activeSeconds)
  // Replacement bars (like the menubar manager) give widgets no service access,
  // so the bar widget reads this file instead.
  readonly property string statusPath: Quickshell.env("HOME") + "/.local/state/eye-breaks/status.json"
  readonly property string barStatus: JSON.stringify({
    minutesLeft: Math.ceil(secondsLeft / 60),
    paused: paused,
    breakOpen: breakOpen
  })
  onBarStatusChanged: if (statusReady) statusFile.setText(barStatus + "\n")
  property bool statusReady: false

  function workoutBreakOpen() {
    var workout = root.shell ? root.shell.serviceFor("nichovski.workout-breaks") : null
    return !!workout && workout.breakOpen === true
  }

  function openBreak() {
    if (root.breakOpen) return "break already open"
    var payload = { seconds: root.breakSeconds, water: (root.breaksDone + 1) % root.waterEvery === 0 }
    root.breakOpen = true
    root.openedAtMs = Date.now()
    if (!root.shell || !root.shell.summon(root.pluginId, JSON.stringify(payload))) {
      root.breakOpen = false
      console.warn("eye-breaks: summon failed")
      return "summon failed"
    }
    return "ok"
  }

  // Called by the overlay when the break ends, whether it ran out or was skipped.
  function finish() {
    if (!root.breakOpen) return
    root.breakOpen = false
    root.breaksDone += 1
    root.activeSeconds = 0
  }

  function tick() {
    if (root.breakOpen) {
      // The overlay never reported back: release the break so later ones still come.
      if (Date.now() - root.openedAtMs > (root.breakSeconds + 60) * 1000) {
        console.warn("eye-breaks: break never finished, releasing it")
        root.breakOpen = false
        root.activeSeconds = 0
      }
      return
    }
    // Away from the screen or moving in a workout break: the eyes are resting.
    if (idleMonitor.isIdle || workoutBreakOpen()) {
      root.activeSeconds = 0
      return
    }
    if (root.paused) return
    root.activeSeconds += root.tickSeconds
    if (root.activeSeconds >= root.workSeconds) openBreak()
  }

  function statusJson() {
    return JSON.stringify({
      activeSeconds: root.activeSeconds,
      secondsLeft: root.secondsLeft,
      breaksDone: root.breaksDone,
      paused: root.paused,
      breakOpen: root.breakOpen,
      idle: idleMonitor.isIdle
    })
  }

  FileView {
    id: statusFile
    path: root.statusPath
    atomicWrites: true
    printErrors: false
  }

  Component.onCompleted: dirMaker.running = true

  Process {
    id: dirMaker
    command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/eye-breaks"]
    onExited: {
      root.statusReady = true
      statusFile.setText(root.barStatus + "\n")
    }
  }

  IdleMonitor {
    id: idleMonitor
    timeout: 60
  }

  Timer {
    interval: root.tickSeconds * 1000
    repeat: true
    running: true
    onTriggered: root.tick()
  }

  IpcHandler {
    target: "eyes"

    function test(): string { return root.openBreak() }
    function pause(): void { root.paused = true }
    function resume(): void { root.paused = false }
    function toggle(): void { root.paused = !root.paused }
    function status(): string { return root.statusJson() }
  }
}
