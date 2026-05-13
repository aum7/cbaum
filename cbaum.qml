import MuseScore 3.0
import QtQuick 
import QtQuick.Controls 
import QtQuick.Layouts

MuseScore {
  version: "1.0"
  description: qsTr("chromatic button accordion")
  pluginType: "dock"
  title: qsTr("chromatic button accordion plugin")

  width: 300
  height: 900

  onRun: {
    console.log("running cba ...")
  }

  property bool allChordsMode: false
  property bool meloBassMode: false
  property bool showRight: false
  property bool showNames: false
  property bool showFingering: false
  property string currentLayout: "C-griff Eu"
  property int tooltipDelay: 377

  readonly property var chordMap: {
   // stradella only 
    "0,4,7": "major",
    "0,3,7": "minor",
    "0,4,7,10": "7",
    "0,3,6": "dim",
    "0,3,6,9": "dim7",
    // expanded (all chords mode)
    "0,4,7,11": "Maj7",
    "0,3,7,10": "m7",
    "0,3,6,10": "m7b5",
    "0,3,7,11": "mMaj7",
    "0,4,8": "aug",
    "0,4,8,10": "7#5",
    "0,4,7,9": "6",
    "0,3,7,9": "m6",
    "0,2,7": "sus2",
    "0,5,7": "sus4",
    "0,5,7,10": "7sus4",
    // extensions (identified via pitch class sets)
    "0,2,4,7": "add9",
    "0,4,7,10,14": "9",
    "0,2,3,7": "m(add9)",
    "0,4,7,10,13": "7b9",
    "0,4,7,10,15": "7#9",
    "0,4,6,10": "7b5",
    "0,4,7,10,14,17": "11",
    "0,4,7,10,14,21": "13",
    "0,4,7,11,14": "Maj9",
    "0,4,7,11,14,21": "Maj13"
  }

  function identifyChord(pitches) {
    var noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    // remove duplicates & normalize to single octave
    var normalized = []
    for (var i = 0; i < pitches.length; i++) {
      var p = pitches[i] % 12
      if (normalized.indexOf(p) === -1) normalized.push(p)
    }
    normalized.sort(function(a, b) { return a - b })
    // todo : split recognition to stradella vs all
    // test notes for potential root
    for (var r = 0; r < normalized.length; r++) {
      var root = normalized[r]
      var currentIntervals = []
      for (var j = 0; j < normalized.length; j++) {
        currentIntervals.push((normalized[j] - root + 12) % 12);
      }
      currentIntervals.sort(function(a, b) { return a - b; })
      var intStr = currentIntervals.join(",")
      if (chordMap[intStr]) {
        return noteNames[root] + " " + chordMap[intStr]
      }
    }
    return qsTr("unknown chord")
  }
  function getSelectedPitch() {
    if (!curScore) {
      console.log(qsTr("no score opened"))
      return
    }
    var elements = curScore.selection.elements
      var pitches = []
    for (var i = 0; i < elements.length; i++) {
      if (elements[i].type === Element.NOTE) {
        pitches.push(elements[i].pitch)
      }
    }
    if (pitches.length < 3) {
      chordLabel.text = qsTr("select 3+ notes")
      return
    }
    pitches.sort(function(a, b) { return a - b })
    chordLabel.text = identifyChord(pitches) 
    // console.log("selected : " + result)
  }
  function addChordText() {
    console.log(qsTr("adding chord text to selected notes"))
  }
  Rectangle {
    id: mainContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 3
      spacing: 10
      // row 1 : chord identification
      RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Button {
          text: qsTr("get chord")
          ToolTip.text: qsTr("get chord from selected notes - min 3")
          ToolTip.visible: hovered
          ToolTip.delay: tooltipDelay
          // ToolTip.timeout:
          onClicked: getSelectedPitch()
        }
        // identify all vs stradella
        CheckBox {
        text: qsTr("all")
        ToolTip.text: qsTr("identify all vs default stradella only chords")
        ToolTip.visible: hovered
        ToolTip.delay:tooltipDelay 
        checked: allChordsMode
        onCheckedChanged: allChordsMode = checked
        contentItem: Text {
          text: parent.text
          color: "white"
          leftPadding: 22
          verticalAlignment: Text.AlignVCenter
          }
        }
        Label {
          text: qsTr("found :")
          ToolTip.text: qsTr("chord identified from selected notes\ncan be added to notes")
          ToolTip.visible: hovered
          ToolTip.delay:tooltipDelay 
          color:"white"
        }
        Label {
          id: foundChordLabel
          text: qsTr("none")
          Layout.fillWidth: true
          color: "dodgerblue"
        }
        // add identified chord as staff text over selected notes
        Button {
          text: qsTr("add")
          ToolTip.text: qsTr("add identified chord to selected notes")
          ToolTip.visible: hovered
          ToolTip.delay: tooltipDelay 
          onClicked: addChordText()
        }
      }
      // row 2 : layout selection +
      RowLayout {
        Layout.fillWidth: true
        spacing: 5
        // Label { text: "layout"; color: "#888"; font.pixelSize: 12 }
        ComboBox {
          id: layoutSelector
          ToolTip.text: qsTr("select desired treble layout")
          ToolTip.visible: hovered
          ToolTip.delay:tooltipDelay 
          Layout.preferredWidth: 120
          // width: parent.width
          model: [
            "C-griff Eu",
            "C-griff 2",
            "B-griff Bayan",
            "B-griff Fin", 
            "D-griff 1",
            "D-griff 2"]
          onActivated: currentLayout = currentText
        }
      }
      // row 3 : buttonboard scheme
      Rectangle {
        id: boardContainer
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "#1a1a1a"
        border.color: "#333"
        Label {
          anchors.centerIn: parent
          text: "board placeholder"
          color: "#444"
        }
      }
    } 
  }
}

