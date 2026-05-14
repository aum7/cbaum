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

  // property bool allChordsMode: false
  property bool meloBassMode: false
  property bool showTreble: false
  property bool showButtonTones: false
  property bool showFingering: false
  property string currentLayout: "C-griff Eu"
  property int rowLeftMargin: 7
  property int rowLeftPadding: 22
  property int tooltipDelay: 777 

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
      if (elements[i].type === Element.NOTE) pitches.push(elements[i].pitch)
    }
    if (pitches.length < 3) {
      foundChordTextField.text = qsTr("select 3+ notes")
      return
    }
    pitches.sort(function(a, b) { return a - b })
    foundChordTextField.text = identifyChord(pitches) 
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
      // row 1 : identify chord buttons & text
      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: rowLeftMargin 
        // Layout.rightMargin: rowLeftMargin 
        spacing: 12
        // identify chord from selected notes
        Button {
          text: qsTr("get chord")
          ToolTip.text: qsTr("get chord from selected notes - min 3")
          ToolTip.visible: hovered
          ToolTip.delay: tooltipDelay
          onClicked: getSelectedPitch()
        }
        // identifed chord text
        TextField {
          id: foundChordTextField
          text: qsTr("none")
          ToolTip.text: qsTr("chord identified from selected notes\ncan be added to notes as text")
          ToolTip.visible: hovered
          ToolTip.delay: tooltipDelay 
          Layout.fillWidth: true
          color: "dodgerblue"
          readOnly: true
          selectByMouse: true
          background: Rectangle { color: "transparent" }
        }
        // add identified chord as staff text above selected notes
        Button {
          text: qsTr("add as text")
          ToolTip.text: qsTr("add identified chord to selected notes")
          ToolTip.visible: hovered
          ToolTip.delay: tooltipDelay 
          onClicked: addChordText()
        }
      }
      // row 2 : checkboxes
      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: rowLeftMargin 
        // Layout.rightMargin: rowLeftMargin 
        spacing: 10
        // use free bass for chord presentation
        CheckBox {
        id: meloBassCbx
        checked: meloBassMode 
        onCheckedChanged: meloBassMode = checked
        text: qsTr("MB")
        ToolTip.text: qsTr("present as melodic / free bass chord")
        ToolTip.visible: hovered
        ToolTip.delay: tooltipDelay 
        contentItem: Text {
        text: parent.text
        color: "white"
        leftPadding: rowLeftPadding 
        verticalAlignment: Text.AlignVCenter
          }
        }
        // show right treble : todo : let be replaced by revealer widget <->
        CheckBox {
        text: qsTr("treble")
        ToolTip.text: qsTr("show right treble vs default left bass buttonboard") 
        ToolTip.visible: hovered
        ToolTip.delay: tooltipDelay 
        checked: showTreble
        onCheckedChanged: showTreble = checked
        contentItem: Text {
          text: parent.text
          color: "white"
          leftPadding: rowLeftPadding 
          verticalAlignment: Text.AlignVCenter
          }
        }
        // show tone names on buttons
        CheckBox {
        text: qsTr("tones")
        ToolTip.text: qsTr("show tone names on buttons")
        ToolTip.visible: hovered
        ToolTip.delay: tooltipDelay 
        checked: showButtonTones
        onCheckedChanged: showButtonTones = checked
        contentItem: Text {
          text: parent.text
          color: "white"
          leftPadding: rowLeftPadding
          verticalAlignment: Text.AlignVCenter
          }
        } 
        // show fingering todo : should be button ???
        CheckBox {
        text: qsTr("fingering")
        ToolTip.text: qsTr("check or add fingering to treble part")
        ToolTip.visible: hovered
        ToolTip.delay: tooltipDelay 
        checked: showFingering
        onCheckedChanged: showFingering = checked
        contentItem: Text {
          text: parent.text
          color: "white"
          leftPadding: rowLeftPadding
          verticalAlignment: Text.AlignVCenter
          }
        } 
      }
      // row 3 : layout selection +
      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: rowLeftMargin 
        spacing: 5
        ComboBox {
          id: layoutSelector
          ToolTip.text: qsTr("select treble layout")
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
      // row 4 : buttonboard scheme
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

