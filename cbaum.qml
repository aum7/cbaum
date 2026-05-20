// musescore 4.7 plugin - chromatic button accordion notes-to-buttons
// based on roland fr 1 xb button v-accordion : can be used for any other
// accordion with similar treble & bass layout
// layouts are from player perspective
// implemented :
//    chord identifier (fixed part) &
//    visual notes-to-buttons presentation (collpsible)
import MuseScore 3.0
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2

MuseScore {
  id: cbaplugin
  version: "1.0"
  description: qsTr("chromatic button accordion visual helper with chord identifier")
  property int windowHeight: 850
  property int collapsedHeight: 57
  property var lastClickTime: 0
  property var doubleClickSpeed: 700
  // toggle buttonboard visibility
  property bool showButtonboard: false 
  property int btnBoardHeight: 70
  property int comboWidth: 110
  // color configuration
  readonly property color darkTheme: "#1a1a1a"
  readonly property color lightTheme: "white"
  readonly property color highlight1: "dodgerblue"
  readonly property color highlight2: "darkorange"
  // playback tracker
  property var trebleActivePitches: []
  property var bassActivePitches: []
  // buttonboard options
  property bool meloBassMode: true
  property bool showButtonTones: true 
  property bool showFingering: false
  property bool showTreble: false
  // range shift
  property int treble8veShift: 0
  property int bass8veShift: 2
  // mysterious options
  property int rowLeftMargin: 7
  property int textLeftPadding: 19 
  property int tooltipDelay: 999
  // buttonboard : treble
  property int buttonSize: 36 
  property int buttonSpacing: 4
  property int buttonFontSize: 34 
  // bass
  property var bassBtnSize: 36
  property var bassBtnSpacing: 3
  property var bassBtnFontSize: 34
  // buttonboard treble layouts
  property var trebleLayouts: [ // name, lowest note, offset from lowest = start MIDI
    { name: "C-griff Europe",start: 55, offset: [0, -1, 1, 0, 2] }, 
    { name: "C-griff 2", start: 56, offset: [3, 1, 2, 0, 1] },
    { name: "B-griff Bayan", start: 55, offset: [3, 1, 2, 0, 1] }, 
    { name: "B-griff Finland", start: 55, offset: [1, 0, 2, 1, 3] },
    { name: "D-griff 1", start: 53, offset: [1, 0, 2, 1, 3] },
    { name: "D-griff 2", start: 55, offset: [2, 0, 1, -1, 0] }
  ]
  property var selectedTrebleLayout: trebleLayouts[0]
  // buttonboard bass layouts
  property var bassLayouts: [ // name, lowest note, offset from lowest = start MIDI
    { name: "minor 3rds",start: 54, offset: [0, 1, 2, 3, 4], vStep: 3 }, // C-griff Europe mirror
    { name: "Bayan", start: 54, offset: [29, 28, 27, 26, 4], vStep: -3 },
    { name: "5ths", start: 54, offset: [24, 28, 12, 16, 4], vStep: 5 }, // todo double-check
    { name: "N. Europe", start: 54, offset: [-1, 1, 3, 5, 4], vStep: 3 }, // b-griff bayan mirror
    { name: "Finnish", start: 54, offset: [-1, 0, 1, 2, 4], vStep: 3 },
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
  // monitor score selection
  Timer {
    interval: 200
    running: true
    repeat: true
    property string lastTonality: ""
    onTriggered: {
      if (!curScore) return
      var elements = curScore.selection.elements
      var tempTreble = []
      var tempBass = [] // split into stradella & melodic bass
      var bassPitches = []
      var bassSolo = false
      var foundChordTonality = ""
      // auto-show buttonboard from notes selection
      for (var i = 0; i < elements.length; i++) {
        if (elements[i].type === Element.NOTE) {
          var pitch = elements[i].pitch
          var track = elements[i].track
          var text = elements[i].parent
          if (track >= 0 && track < 4) { // track 0-3 = treble staff
            showTreble = true
            var shiftedPitch = pitch - treble8veShift
            if (tempTreble.indexOf(shiftedPitch) === -1) {
              tempTreble.push(shiftedPitch)
            }
          } else if (track >= 4 && track < 8) { // bass staff
            showTreble = false
            if (bassPitches.indexOf(pitch) === -1) {
              bassPitches.push(pitch)
            }
            if (text && text.parent) {
              var seg = text.parent
              if (seg.annotations) {
                for (var j = 0; j < seg.annotations.length; j++) {
                  var ann = seg.annotations[j]
                  if (ann.type === Element.STAFF_TEXT) {
                    var annTxt = ann.text.trim()
                    var annTxtLower = annTxt.toLowerCase().replace(/\./g, "")
                    if (annTxtLower === "sb" || annTxtLower === "bs") {
                      bassSolo = true
                      console.log("bassSolo !")
                    } else if (annTxt === "M" || annTxt === "m" ||
                      annTxt === "7" || annTxt === "o") {
                        foundChordTonality = annTxt
                    } else {
                      // get chord from chord marking above note(s)
                      var chordMatch = annTxt.match(/^[A-G][#b♮♯♭]?(.*)$/i)
                      if (chordMatch) {
                        var suffix = chordMatch[1].trim().toLowerCase()
                        if (suffix.indexOf("dim") !== -1 || suffix.indexOf("o") !== -1) {
                          foundChordTonality = "o"
                        } else if (suffix.indexOf("7") !== -1 || suffix.indexOf("9") !== -1) {
                          foundChordTonality = "7"
                        } else if (suffix.indexOf("m") === 0 || suffix.indexOf("min") === 0) {
                          foundChordTonality = "m"
                        } else if (suffix === "" || suffix.indexOf("maj") === 0 ||
                          suffix === "M") {
                          foundChordTonality = "M"
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
      if (foundChordTonality !== "") {
        console.log("tonality=", foundChordTonality)
        lastTonality = foundChordTonality
      } else {
        foundChordTonality = lastTonality
      }
      if (meloBassMode) { // match exact pitches across all board buttons
        for (var i = 0; i < bassPitches.length; i++) {
          // allow for shifting octaves, as 5 bass layouts span 5th > 2nd octave
          var targetPitch = bassPitches[i] - bass8veShift
          for (var r = 0; r < 12; r++) {
            for (var c = 0; c < 4; c++) {
              if (mapMelodicBass(r, c) === targetPitch) {
                tempBass.push(r + "," + c)
              }
            }
          }
        }
      } else { // stradella
        if (bassSolo) {
          for (var i = 0; i < bassPitches.length; i++) {
            var targetPitchClass = bassPitches[i] % 12
            for (var r = 0; r < 12; r++) {
              if (((42 + r * 5) % 12) === targetPitchClass) tempBass.push(r + ",4")
              if (((42 + r* 5 + 4) % 12) === targetPitchClass) tempBass.push(r + ",5")
            }
          }
        } else if (foundChordTonality !== "" && bassPitches.length === 1
          && bassPitches[0] >= 50) {
          var targetCol = -1
          if (foundChordTonality === "o") targetCol = 0
          if (foundChordTonality === "7") targetCol = 1
          if (foundChordTonality === "m") targetCol = 2
          if (foundChordTonality === "M") targetCol = 3
          var targetPitchClass = bassPitches[0] % 12
          for (var r = 0; r < 12; r++) {
            var fbPitchClass = (42 + r * 5) % 12
            if (fbPitchClass === targetPitchClass) {
              if (targetCol !== -1) {
                tempBass.push(r + "," + targetCol)
              }
              tempBass.push(r + ",4")
              tempBass.push(r + 4 + ",5")
            }
          }
        } else {
        var singleNotes = []
        var chordNotes = []
        for (var i = 0; i < bassPitches.length; i++) {
          if (bassPitches[i] <= 50) {
            singleNotes.push(bassPitches[i])
          } else {
            chordNotes.push(bassPitches[i])
          }
        }
        for (var i = 0; i < singleNotes.length; i++) {
          var targetPitchClass = singleNotes[i] % 12
          for (var r = 0; r < 12; r++) {
            if (((42 + r * 5) % 12) === targetPitchClass) tempBass.push(r + ",4")
            if (((42 + r * 5 + 4) % 12) === targetPitchClass) tempBass.push(r + ",5")
          }
        }
        if (chordNotes.length >= 3 || 
          (chordNotes.length > 0 && bassPitches.length >= 3)) {
          var notesToDetect = chordNotes.length >= 3 ? chordNotes : bassPitches
          notesToDetect.sort(function(a, b) { return a - b })
          var normalized = []
          for (var k = 0; k < notesToDetect.length; k++) {
            var p = notesToDetect[k] % 12
            if (normalized.indexOf(p) === -1) normalized.push(p)
          }
          var foundChordCol = -1
          var rootNoteClass = -1
          for (var n = 0; n < normalized.length; n++) {
            var root = normalized[n]
            var mask = 0
            for (var j = 0; j < normalized.length; j++) {
              var interval = (normalized[j] - root + 12) % 12
              mask |= (1 << interval)
            }
            if (chordMap[mask] !== undefined) { // check against chord map
              var suffix = chordMap[mask]
              rootNoteClass = root
              if (suffix === "dim" || suffix === "dim7") foundChordCol = 0
              else if (suffix === "7" || suffix === "9") foundChordCol = 1
              else if (suffix === "m" || suffix === "m6" || suffix === "m7") 
                foundChordCol = 2 
              else if (suffix === "" || suffix === "Maj7") foundChordCol = 3 // major
              break
            }
          }
          if (rootNoteClass !== -1) {
            // highlight bass fb & cb columns
            for (var r = 0; r < 12; r++) {
              var fbPitchClass = (42 + r * 5) % 12
              if (fbPitchClass === rootNoteClass) {
                if (foundChordCol !== -1) {
                  tempBass.push(r + "," + foundChordCol)
                }
              }
            }
          }
        } else if (bassPitches.length === 1) {
          var targetPitchClass = bassPitches[0] % 12
          for (var r = 0; r < 12; r++) {
            if (((42 + r * 5) % 12) === targetPitchClass) tempBass.push(r + ",4")
            if (((42 + r * 5 + 4) % 12) === targetPitchClass) tempBass.push(r + ",5")
          }
        }
      } 
    }  
    trebleActivePitches = tempTreble
    bassActivePitches = tempBass
    }
  }
  // fingering text
  function hideFinger() {
    if (!curScore || curScore.selection.elements.length === 0) {
      console.log("hideFinger : no score or nothing selected : exiting ...")
      return
    }
    // start command
    curScore.startCmd()
    // cursor for navigation of score
    var elements = curScore.selection.elements
    for (var i = 0; i < elements.length; i++) {
      var note = elements[i]
      if (note.type != Element.NOTE) continue
      var existing = getExistingFinger(note)
      if (existing) {
        existing.visible = false
      }
    }
    curScore.endCmd()
  }
  
  function getExistingFinger(note) {
    for (var i = 0; i < note.elements.length; i++) {
      if (note.elements[i].type == Element.FINGERING) return note.elements[i]
    }
    return null
  }

  function calcFinger(requestAlternate) {
    if (!curScore || curScore.selection.elements.length === 0) {
      console.log("calcFinger : no score or nothing selected : exiting ...")
      return
    }
    var sel = curScore.selection
    if (!sel.startSegment || !sel.endSegment) {
      console.log("calcFinger : active selection has no proper start / end segments")
      return
    }
    // wrap into commmand
    curScore.startCmd()
    var startTick = sel.startSegment.tick
    var endTick = sel.endSegment.tick
    // gather melody data
    var notesSequence = []
    // console.log("calcFinger : notesSequence=", notesSequence)
    var cursor = curScore.newCursor()
    // cursor.track = sel.elements[0].track
    cursor.rewind(Cursor.SELECTION_START)
    while (cursor.segment && cursor.tick < endTick) {
      if (cursor.tick >= startTick &&
        cursor.element && cursor.element.type == Element.CHORD) {
        var chord = cursor.element
        if (chord.notes.length > 0) {
          var topNote = chord.notes[chord.notes.length - 1]
          notesSequence.push({
            pitch: topNote.pitch,
            noteElement: topNote,
            tick: cursor.tick
          })
        }
      }
      cursor.next()
    }
    // process
    for (var i = 0; i < notesSequence.length; i++) {
      var current = notesSequence[i]
      var note = current.noteElement
      var prev = (i > 0) ? notesSequence[i - 1] : null
      var next = (i < notesSequence.length - 1) ? notesSequence[i + 1] : null
      // detect direction for closer-to rule
      var direction = 0 // 0=stable 1=higher note next -1=lower note next
      if (next) {
        if (next.pitch > current.pitch) direction = 1
        else if (next.pitch < current.pitch) direction = -1
      }
      // lookahead to catch 3-note chromatic run
      var isChromatic = (next && prev) &&
        (Math.abs(current.pitch - prev.pitch) == 1 &&
        Math.abs(next.pitch - current.pitch) == 1)
      // internal logic engines
      var existing = getExistingFinger(note)
      // console.log("calcFinger : existing=", existing)
      if (existing) {
        existing.visible = true
        if (requestAlternate) {
          existing.text = getFinger(current.pitch, direction, isChromatic,
            requestAlternate, prev, next)
        }
      } else {
        var fingerText = newElement(Element.FINGERING)
        // fingerText.track = note.track
        fingerText.text = getFinger(current.pitch, direction, isChromatic,
          requestAlternate, prev, next)
        fingerText.placement = Placement.ABOVE  
        note.add(fingerText)
      }
    }
    curScore.endCmd()
  }
  
  function getFinger(pitch, direction, isChromatic, requestAlternate, prev, next) {
    var noteClass = pitch % 12 // todo more dynamic results we wanna
    var cFinger = "3"
    var bFinger = "3"
    // alternate logic : direction-based priority
    if (requestAlternate) {
      if (direction === 1) {
        cFinger = (noteClass % 2 === 0) ? "4" : "5"
        bFinger = "4"
      } else if (direction === -1) {
        cFinger = (noteClass % 2 === 0) ? "2" : "3"
        bFinger = "2"
      } else {
        // no direction : last note : relation to previous
        if (prev) {
          var interval = pitch - prev.pitch
          if (interval > 0) {
            cFinger = "5"
            bFinger = "4"
          } else {
            cFinger = "2"
            bFinger = "3"
          }
        } else {
          cFinger = "1"
          bFinger = "5"
        }
      }
      return cFinger + "\n" + bFinger
    }
    // base logic : populate 
    if (noteClass === 0) { // president rule 2@C
      cFinger = "2" 
      bFinger = "2"
    } else if (noteClass === 2) { // D
      cFinger = "3" 
      bFinger = "4"
    } else if (noteClass === 4) { // E
      cFinger = "4"
      bFinger = "3"
    } else if (noteClass === 5) { // F
      cFinger = "3"
      bFinger = "4"
    } else if (noteClass === 7) { // G
      cFinger = "4"
      bFinger = "3"
    } else if (isChromatic) {
      cFinger = (noteClass === 1 || noteClass === 2) ? "1" : "2"
      // todo bFinger
    } else if (direction === -1) { // closer-to higher
      cFinger = "2"
      bFinger = "2"
    } else if (direction === 1) {
      cFinger = "4"
      bFinger = "4"
    }
    return cFinger + "\n" + bFinger
  }

  function mapButtonToMidi(row, col) {
    var base = selectedTrebleLayout.start
    var off = selectedTrebleLayout.offset[col]
    return (base + off) + (row * 3)
  }
  function mapMelodicBass(row, col) {
    var stradellaFB = 42 + (row * 5) // 5ths
    if (!meloBassMode) { // stradella standard
      if (col === 5) return stradellaFB + 4
      return stradellaFB
      } else {
        if (col >= 4) {
          return (col === 5) ? (stradellaFB + 4) : stradellaFB
        }
      var base = selectedBassLayout.start
      var off = selectedBassLayout.offset[col]
      var step = selectedBassLayout.vStep
      // bass 3 5ths needs extra lowe
      if (selectedBassLayout.name === "5ths") {
        var targetPitch = (base + off) + (row * step)
        while (targetPitch > 83) targetPitch -= 12
        while (targetPitch < 60) targetPitch += 12
        return targetPitch
      }
      return (base + off) + (row * step)
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
      foundChordLabel.text = qsTr("select 3+ notes")
      return
    }
    pitches.sort(function(a, b) { return a - b })
    foundChordLabel.text = identifyChord(pitches) 
  }
  function addChordText() {
    // console.log(qsTr("adding chord text to selected notes"))
    var chordFound = foundChordLabel.text
    if (!chordFound || 
      chordFound === "none" || 
      chordFound === "unknown" || 
      chordFound.indexOf("select") !== -1) return
    var selection = curScore.selection.elements
    if (selection.length === 0) {
      console.log("[addChordText] nothing selected : exiting ...")
      return
    }
    // find 1st note of chord to get valid segment
    var firstNote = null
    for (var i = 0; i < selection.length; i++) {
      if (selection[i].type === Element.NOTE) { 
        firstNote = selection[i]
        break
      }
    }
    if (!firstNote) {
      console.log("[addChordText] no firstNote : exiting ...")
      return
    }
    console.log("[addChordText] firstNote=" + firstNote)
    console.log("[addChordText] firstNote.track=" + firstNote.track)

    curScore.startCmd()
    var textObj = newElement(Element.STAFF_TEXT)
    textObj.text = chordFound
    var cursor = curScore.newCursor()
    cursor.track = firstNote.track  // point auto-assigned track
    console.log("[addChordText] cursor.track=" + cursor.track)
    cursor.rewind(0) // (Cursor.SELECTION_START)  // start of score
    var targetTick = firstNote.parent.parent.tick
    // fast forward
    while (cursor.segment && cursor.tick < targetTick) {
      cursor.next()
    }
    // write to score
    if (cursor.segment && cursor.tick === targetTick) {
      cursor.add(textObj)
    } else {
      // fallback
      if (firstNote.parent) {
        firstNote.parent.add(textObj)
      }
    }
    curScore.endCmd()
  }
  // funcions end
  Window {
    id: mainWindow
    title: qsTr("poland chroma-button-accordion      ")
    flags: Qt.Window | Qt.WindowMinimizeButtonHint | Qt.WindowCloseButtonHint |
      Qt.WindowStaysOnTopHint // | Qt.WindowTitleHint | Qt.WindowSystemMenuHint
    width: 300
    height: showButtonboard ? windowHeight : collapsedHeight
    x: 0 // move to left edge
    y: 108 // move down from top
    visible: true
    color: darkTheme
    
    Column { // has single column
      id: mainWidget
      width: parent.width
      height: parent.height
      anchors.fill: parent
      topPadding: 5
      Row { // chord identifier
        id: row1
        height: 30
        spacing: 4
        anchors.horizontalCenter: parent.horizontalCenter
        Button {
          id: getChordBtn
          text: qsTr("get chord")
          ToolTip.text: qsTr("get chord from selected notes - min 3" +
            "\ncan be added to selected notes" +
            "\nnotes need be shift-selected, ie have square" +
            "\nctrl-selected notes will not work")
          ToolTip.visible: hovered
          ToolTip.delay: tooltipDelay 
          onClicked: getSelectedPitch()
        }
        Label {
          id: foundChordLabel
          text: qsTr("none")
          width: 114
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          font.pixelSize: 18
          minimumPixelSize: 10
          color: "dodgerblue"
          padding: 0
          fontSizeMode: Text.Fit
        }
        Button {
          id: addAsTextBtn
          text: qsTr("add as text")
          ToolTip.text: qsTr("add identified chord to selected notes")
          ToolTip.visible: hovered
          ToolTip.delay: tooltipDelay 
          onClicked: addChordText()
        }
      }
      // toggle separator
      Rectangle {
        id: handleBackground
        width: parent.width
        height: 22 
        color: "#272727"
        Rectangle {
          id:toggleHandle
          width: 64
          height: 12
          radius: 4
          anchors.centerIn: parent
          color: toggleBtnBrdMouseArea.containsMouse ? highlight1 : "#3c3c3c"
        }
        MouseArea {
          id: toggleBtnBrdMouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            showButtonboard = !showButtonboard
            // made mu3 collapse bottom panel
            var targetHeight = showButtonboard ? windowHeight : collapsedHeight
            cbaplugin.height = targetHeight
            mainWindow.height = targetHeight
          }
        }
      }
      // wrap row2 + row3 + row4 + buttonboard into container
      Column {
        id: buttonboard
        width: parent.width
        visible: showButtonboard
        spacing: 10
        // row2 
        Row { // checkboxes
          id: row2
          height: 20
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 7
          // use melodic / free bass for chord presentation
          CheckBox {
            id: meloBassCbx
            text: qsTr("MB") // for majority langs this can stay MB ???
            checked: meloBassMode 
            onCheckedChanged: meloBassMode = checked
            ToolTip.text: qsTr("present as melodic / free bass chord" +
              "\nvs default stradella bass")
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
          // show fingering
          CheckBox {
            id: fingerCbx
            text: qsTr("fingering")
            ToolTip.text: qsTr("add, change or hide fingering in treble part" +
              "\ndouble-click to alternate fingering")
            ToolTip.visible: hovered
            ToolTip.delay: tooltipDelay 
            checked: showFingering
            onCheckedChanged: showFingering = checked
            onClicked: {
              var currentTime = new Date().getTime()
              // detect double-click
              if (currentTime - lastClickTime < doubleClickSpeed) {
              console.log("onClicked : alternate fingering ...")
              checked = true
              calcFinger(true)
              } else {
                if (checked) {
                  console.log("onClicked : initial fingering ...")
                  calcFinger(false) // initial calculation
                } else {
                  console.log("onClicked : hiding fingering ...")
                  hideFinger()
                }
              }
              lastClickTime = currentTime
            }
            contentItem: Text {
              text: parent.text
              color: "white"
              leftPadding: textLeftPadding
              verticalAlignment: Text.AlignVCenter
            } 
          }
        }
        // row 3 
        Row { // treble layout selection
          id: row3
          height: 25
          spacing: 12
          anchors.horizontalCenter: parent.horizontalCenter
          ComboBox { // treble selector
            id: trebleSelector
            width: comboWidth
            ToolTip.text: qsTr("select treble layout")
            ToolTip.visible: hovered
            ToolTip.delay: tooltipDelay 
            model: trebleLayouts
            textRole: "name"
            onActivated: function(index) { selectedTrebleLayout = trebleLayouts[index] }
          }
          ComboBox { // treble 8ve selector
            id: treble8veSelector
            width: 52
            currentIndex: 0 // set default model choice
            ToolTip.text: qsTr("select treble 8ve\n0=3rd | -12=2nd | -24=1st")
            ToolTip.visible: hovered
            ToolTip.delay: tooltipDelay 
            model: [0, -12, -24]
            onActivated: function(index) { treble8veShift = model[index] }
          }
        }
        // row 4 
        Row { // bass layout selection
          id: row4
          height: 30
          spacing: 12
          anchors.horizontalCenter: parent.horizontalCenter
          ComboBox { // bass selector
            id: bassSelector
            width: comboWidth 
            ToolTip.text: qsTr("select bass layout")
            ToolTip.visible: hovered
            ToolTip.delay: tooltipDelay 
            model: bassLayouts
            textRole: "name"
            onActivated: function(index) { selectedBassLayout = bassLayouts[index] }
          }
          ComboBox { // 8ve selector
            id: bass8veSelector
            width: 52
            currentIndex: 2 // set default model choice
            ToolTip.text: qsTr("select bass 8ve\n24=5th | .. | 0=3rd | .. | -24=1st" +
              "\nfor melodic / free bass only")
            ToolTip.visible: hovered
            ToolTip.delay: tooltipDelay 
            model: [24, 12, 0, -12, -24]
            onActivated: function(index) { bass8veShift = model[index] }
          }
        }
        Column { // buttonboards
          id: boardWidget
          width: parent.width
          spacing: 20
          // treble board
          Item {
            id: trebleBrdItem
            width: parent.width
            height: trebleRow.height
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
                      // selection (playback) highlight
                      property bool isSelected: trebleActivePitches.indexOf(pitch) !== -1
                      // calculate pitch
                      property int pitch: mapButtonToMidi(index, colIndex)
                      // determine button color
                      property bool black: isBlackButton(pitch)
                      color: isSelected ? highlight1 :
                      (black ? "#333333" : "#eeeeee")
                      border.color: "#777777"
                      border.width: 1
                      Text {
                        anchors.centerIn: parent
                        text: !black ? getNoteName(pitch) : ""
                        visible: !black && showButtonTones // only show naturals
                        font.pixelSize: buttonFontSize
                        color: (black || isSelected) ? "white" : "black"
                      }
                    }
                  }
                }
              }
            }
          }
          // bass board
          Item { // accidentals included
            id: bassBrdItem
            width: parent.width
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
                  id: columnDelegate
                  property int col: index
                  spacing: bassBtnSpacing
                  topPadding: col * (bassBtnSize / 2)
                  Repeater {
                    model: 12 // tones in 72 bass-buttons accordion
                    delegate: Rectangle {
                      id: rowDelegate
                      property int row: index
                      width: bassBtnSize
                      height: bassBtnSize
                      radius: bassBtnSize / 2
                      // highlight when selected by user
                      property bool isSelected: { 
                        var coordStr = row + "," + columnDelegate.col
                        return bassActivePitches.indexOf(coordStr) !== -1
                        }
                      // converter logic
                      property int pitch: mapMelodicBass(row, columnDelegate.col)
                      property bool black: isBlackButton(pitch)
                      color: isSelected ? highlight2 : (black ? "#333333" : "#eeeeee")
                      border.color: "#777777"
                      Text {
                        text: {
                          if (columnDelegate.col === 4 || columnDelegate.col === 5) {
                            return getNoteName(pitch)
                          }
                          if (!meloBassMode) {
                            if (rowDelegate.row === 0 || 
                              rowDelegate.row === 6 || 
                              rowDelegate.row === 11) {
                              var chordLabels = ["o", "7", "m", "M"]
                              return chordLabels[columnDelegate.col]
                            }
                            return ""
                          }
                          // fallback for melodic bass mode
                          return getNoteName(pitch)
                        }
                        font.pixelSize: text.length > 1 ? 
                          bassBtnFontSize * 0.68 : 
                          bassBtnFontSize
                        color: (black || isSelected) ? "white" : "black"
                        visible: showButtonTones
                        anchors.centerIn: parent
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
  onRun: {
    console.log("cba plugin started")
    mainWindow.showNormal()
  }
}
