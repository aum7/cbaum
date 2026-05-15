import MuseScore 3.0
import QtQuick 
import QtQuick.Controls 
import QtQuick.Layouts

MuseScore {
  id: cbaplugin
  version: "1.0"
  description: qsTr("chromatic button accordion")
  pluginType: "dock"
  title: qsTr("chromatic button accordion plugin")
  width: 300
  height: 790
  onRun: {
    console.log("running cba ...")
  }
  // toggable panel for visual buttonboard
  // property bool panelExpanded: false
  // buttonboard options
  property bool meloBassMode: false
  property bool showButtonTones: false
  property bool showFingering: false
  property bool showTreble: false
  // property string currentLayout: "C-griff Europe" // not used
  // mysterious options
  property int rowLeftMargin: 7
  property int textLeftPadding: 19 
  property int tooltipDelay: 999
  // buttonboard : treble
  property var trebleLayout: []  // to be populated with button objects
  property int buttonSize: 36 
  property int buttonSpacing: 4
  property int buttonFontSize: 34 
  // bass
  property var bassLayout: []
  property var bassBtnSize: 36
  property var bassBtnSpacing: 3
  property var bassBtnFontSize: 34
  // buttonboard treble layouts
  property var layouts: [ // name, lowest note, offset from lowest = start MIDI
    { name: "C-griff Europe",start: 55, offset: [0, -1, 1, 0, 2] }, 
    { name: "C-griff 2", start: 56, offset: [3, 1, 2, 0, 1] },
    { name: "B-griff Bayan", start: 55, offset: [3, 1, 2, 0, 1] }, 
    { name: "B-griff Finland", start: 55, offset: [1, 0, 2, 1, 3] },
    { name: "D-griff 1", start: 53, offset: [1, 0, 2, 1, 3] },
    { name: "D-griff 2", start: 55, offset: [2, 0, 1, -1, 0] }
  ]
  property var selectedLayout: layouts[0]
  // buttonboard bass layouts
  property var bassLayouts: [ // name, lowest note, offset from lowest = start MIDI
    { name: "minor 3rds",start: 54, offset: [0, 1, 2, 3, 4] }, // C-griff Europe mirror
    { name: "Bayan", start: 55, offset: [3, 1, 2, 0, 1] }, // todo C-griff 2
    { name: "5ths", start: 55, offset: [3, 1, 2, 0, 1] }, // todo B-griff Bayan
    { name: "N. Europe", start: 55, offset: [1, 0, 2, 1, 3] }, // todo B-griff Finland ; b-griff baan mirror
    { name: "Finnish", start: 53, offset: [1, 0, 2, 1, 3] }, // todo D-griff 1
  ]
  property var selectedBassLayout: bassLayouts[0]
  readonly property var chordMap: { // bitmask matrix
    // basic
    "145":  "",       // major
    "137":  "m",      // minor
    "273":  "aug",    // aug
    "73":   "dim",    // dim
    "585":  "dim7",   // dim7
    // 7s & 6s
    "1169": "7",      // 7
    "1041": "7",      // 7 with dropped 5th
    "2193": "Maj7",   // Maj7
    "2065": "Maj7",   // Maj7 with dropped 5th
    "1161": "m7",     // m7
    "1033": "m7",     // m7 with drepped 5th
    "1097": "m7b5",   // m7b5
    "657":  "6",      // 6
    "649":  "m6",     // m6
    "1173": "9",      // 9
    // suspended
    "161":  "sus4",   // sus4
    "141":  "sus2",   // sus2
    "1185": "7sus4"   // 7sus4
  }
  function mapButtonToMidi(row, col) {
    var base = selectedLayout.start
    var off = selectedLayout.offset[col]
    // var step todo skip / delete ???
    return (base + off) + (row * 3)
  }
  function mapMelodicBass(row, col) {
    if (!meloBassMode) { // stradella standard
      var stradellaFB = 42 - (row * 5) // 5ths
      switch (col) {
        case 0: return stradellaFB + 4 // cb
        case 1: return stradellaFB  // fb
        case 2: return stradellaFB  // xx
        case 3: return stradellaFB  // xx
        case 4: return stradellaFB  // xx
        case 5: return stradellaFB  // xx
        default: return 0
      }
    } else { // melodic / free bass
      if (col === 0) return stradellaFB + 4 // 4 semitones from FB to CB
      if (col === 1) return stradellaFB
      var base = selectedBassLayout.start
      var offsetIdx = 5 - col
      var off = selectedBassLayout.offset[offsetIdx]
      return (base + off) + (row * 3)
    }
  }
  function isBlackButton(pitch) {
    var p = pitch % 12
    return (p === 1 || p === 3 || p === 6 || p === 8 || p === 10)
  }
  function getNoteName(pitch) {
    var names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    return names[pitch % 12]
  }
  function initTreble() {
    var layout = []
    var rows = 5
    var cols = 17
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        layout.push({
          "row": r,
          "col": c,
          "x": c * (buttonSize + buttonSpacing) + (r % 2 * (buttonSize / 2)),
          "y": r * (buttonSize + buttonSpacing),
          "pitch": 0, // calculate from buttonboard layout
          "isWhite": true // naturals
        })
      }
    }
    trebleLayout = layout
  }
  function identifyChord(pitches) {
    var normalized = []
    for (var i = 0; i < pitches.length; i++) {
      var p = pitches[i] % 12
      if (normalized.indexOf(p) === -1) normalized.push(p)
    }
    // lowest selected note
    var bassNote = (pitches[0] % 12 + 12) % 12
    for (var r = 0; r < normalized.length; r++) {
      var root = normalized[r]
      var mask = 0
      // calculate 12-bit fingerprint relative to root
      for (var j = 0; j < normalized.length; j++) {
        var interval = (normalized[j] - root + 12) % 12
        mask |= (1 << interval)
      }
      // check against our bitmask map
      if (chordMap[mask] !== undefined) {
        var suffix = chordMap[mask]
        var chordName = getNoteName(root) + suffix
        // add slash bass notation if root isnt bottom mote
        if (root !== bassNote) {
          chordName += "/" + getNoteName(bassNote)
        }
        return chordName
      }
    }
    return qsTr("unknown")
  }
  function getSelectedPitch() {
    // selected note in ms score opened : runs on get chord button click
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
  }
  function addChordText() {
    // console.log(qsTr("adding chord text to selected notes"))
    var chord = foundChordTextField.text
    if (!chord || 
      chord === "none" || 
      chord === "unknown" || 
      chord.indexOf("select") !== -1) return
    var selection = curScore.selection.elements
    if (selection.length === 0) {
      console.log("[addChordText] nothing selected : exiting ...")
      return
    }
    // find 1st ote or chord to get valid segment
    var firstNote = null
    for (var i = 0; i < selection.length; i++) {
      if (selection[i].type === Element.NOTE) { 
        firstNote = selection[i]
        break
      }
    }
    if (!firstNote) {
      console.log("[addChordText] no firstNorte : exiting ...")
      return
    }

    curScore.startCmd()
    var cursor = curScore.newCursor()
    cursor.track = firstNote.track // point specific staff & voice
    cursor.inputStateMode = Cursor.INPUT_STATE_SYNC_WITH_SCORE // get segment
    var targetTick = firstNote.parent.parent.tick // segment

    cursor.rewind(0)  // start of score
    while (cursor.segment && cursor.tick < targetTick) {
      cursor.next()
    }
    // inject
    var text = newElement(Element.STAFF_TEXT)
    text.text = chord
    // add text directly to segment on specific track
    if (cursor.segment) {
      cursor.add(text)
    }
    curScore.endCmd()
  }
  // funcions end
  Column { // has single column
    id: mainWidget
    anchors.fill: parent
    width: parent.width
    // color: "transparent"
    Row { // chord identifier
      id: row1
      height: 30 // Hard fixed height
      spacing: 4
      anchors.horizontalCenter: parent.horizontalCenter
      Button {
        text: qsTr("get chord")
        ToolTip.text: qsTr("get chord from selected notes - min 3
          \ncan be added to selected notes")
        ToolTip.visible: hovered
        ToolTip.delay: tooltipDelay 
        onClicked: getSelectedPitch()
      }
      TextField {
        id: foundChordTextField
        text: qsTr("none")
        Layout.fillWidth: true
        color: "dodgerblue"
        readOnly: true
      }
      Button {
        text: qsTr("add as text")
        ToolTip.text: qsTr("add identified chord to selected notes")
        ToolTip.visible: hovered
        ToolTip.delay: tooltipDelay 
        onClicked: addChordText()
      }
    }
    // row2 
    Row { // checkboxes
      id: row2
      height: 30
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 7
      // use free bass for chord presentation
      CheckBox {
        id: meloBassCbx
        text: qsTr("MB") // for majority langs this can stay MB ???
        checked: meloBassMode 
        onCheckedChanged: meloBassMode = checked
        ToolTip.text: qsTr("present as melodic / free bass chord vs default stradella bass")
        ToolTip.visible: hovered
        ToolTip.delay: tooltipDelay 
        contentItem: Text {
          text: parent.text
          color: "white"
          leftPadding: textLeftPadding 
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
          leftPadding: textLeftPadding
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
          leftPadding: textLeftPadding
          verticalAlignment: Text.AlignVCenter
        } 
      }
      // show treble (default) vs bass buttonboard
      CheckBox {
        text: qsTr("treble")
        ToolTip.text: qsTr("show treble (default) vs bass buttonboard")
        ToolTip.visible: hovered
        ToolTip.delay: tooltipDelay 
        checked: showTreble
        onCheckedChanged: showTreble = checked
        contentItem: Text {
          text: parent.text
          color: "white"
          leftPadding: textLeftPadding
          verticalAlignment: Text.AlignVCenter
        } 
      }
    }
    // row 3 
    Row { // layout selection
      id: row3
      height: 40
      spacing: 18
      anchors.horizontalCenter: parent.horizontalCenter
      ComboBox { // bass selector
        id: bassSelector
        ToolTip.text: qsTr("select bass layout")
        ToolTip.visible: hovered
        ToolTip.delay:tooltipDelay 
        Layout.preferredWidth: 120
        model: bassLayouts
        textRole: "name"
        onActivated: function(index) { selectedBassLayout = bassLayouts[index] }
      }
      ComboBox { // treble selector
        id: trebleSelector
        ToolTip.text: qsTr("select treble layout")
        ToolTip.visible: hovered
        ToolTip.delay:tooltipDelay 
        Layout.preferredWidth: 120
        model: layouts
        textRole: "name"
        onActivated: function(index) { selectedLayout = layouts[index] }
      }
    }
    Column {
      id: boardWidget
      // width: parent.width
      width: parent.width
      spacing: 20
      // treble board
      Item {
        id: trebleBoard
        width: parent.width
        // height: trebleRow.height
        height: showTreble ? trebleRow.height : 0
        visible: showTreble
        Row {
          id: trebleRow
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: buttonSpacing // 6 // creates vertical overlap for honeycomb
          Repeater {
            model: 5 // 5 rows of cba
            delegate: Column {
              property int colIndex: index
              spacing: buttonSpacing // 8  // vertical spacing between buttons
              topPadding: (colIndex % 2 === 0) ? 15 : 0 // half button offset
              Repeater {
                model: (colIndex % 2 === 0) ? 16 : 17 
                delegate: Rectangle {
                  width:buttonSize 
                  height: buttonSize
                  radius: buttonSize / 2 
                  // calculate pitch
                  property int pitch: mapButtonToMidi(index, colIndex)
                  // determine button color
                  property bool black: isBlackButton(pitch)
                  color: black ? "#333333" : "#eeeeee"
                  border.color: "#666666"
                  border.width: 1
                  Text {
                    anchors.centerIn: parent
                    text: !black ? getNoteName(pitch) : ""
                    visible: !black && showButtonTones // only show naturals
                    font.pixelSize: buttonFontSize
                    color: "black"
                  }
                }
              }
            }
          }
        }
      }
      // bass board
      Item {
        id: bassBoard
        width: parent.width
        // height: (12 * (bassBtnSize + bassBtnSpacing)) + (5 * (bassBtnSize / 2))
        height: !showTreble ? bassRow.height : 0
        visible: !showTreble
        Row {
          id: bassRow
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          spacing: bassBtnSpacing
          layoutDirection: Qt.LeftToRight
          Repeater {
            model: ["o", "7", "m", "M", "fb", "cb"]
            delegate: Column {
              property int col: index
              spacing: bassBtnSpacing
              topPadding: col * (bassBtnSize / 2)
              Repeater {
                model: 12 // tones in 72 bass-button case
                delegate: Rectangle {
                  width: bassBtnSize
                  height: bassBtnSize
                  radius: bassBtnSize / 2
                  // converter logic
                  property int pitch: mapMelodicBass(index, 5 - col)
                  property bool black: isBlackButton(pitch)
                  color: black ? "#333333" : "#eeeeee"
                  border.color: "#666666"
                  Text {
                    anchors.centerIn: parent
                    text: getNoteName(pitch)
                    visible: !black && showButtonTones
                    font.pixelSize: bassBtnFontSize
                    color: "black"
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
