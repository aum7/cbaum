// musescore 4.7 plugin - chromatic button accordion notes-to-buttons
// based on roland fr 1 xb button v-accordion : can be used for any other
// accordion with similar treble & bass layout
// layouts are from player perspective
// implemented :
//    automatic chord identifier (fixed part) &
//    visual notes-to-buttons presentation (collapsible)
//    automatic selection of treble or bass
import MuseScore 3.0
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.VectorImage
// import "translations/translations.js" as I18n

MuseScore {
  id: cbaplugin
  version: "1.0"
  description: qsTr("chromatic button accordion visual helper with chord identifier")
  Component.onCompleted: {
    var localeName = Qt.locale().name
    var lang = localeName.split("_")[0]
    console.log("cbaplugin host language=", lang)
    }
  property int expandedHeight: 836
  property int collapsedHeight: 57
  property var lastClickTime: 0
  property var doubleClickSpeed: 700
  property var showTooltips: false
  property int iconSize: 30 
  // toggle buttonboard visibility
  property bool showButtonboard: true 
  property int comboWidth: 110
  // color configuration
  readonly property color darkTheme: "#1a1a1a"
  // readonly property color lightTheme: "white"
  readonly property color highlight1: "dodgerblue"
  readonly property color highlight2: "darkorange"
  readonly property color highlight3: "green"
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
  property var bassLayouts: [ // name, lowest note, offset from lowest, step from previous
    // C-griff Europe mirror
    { name: "minor 3rds",start: 54, offset: [0, 1, 2, 3, 4], vStep: 3 },
    // speciality
    { name: "Bayan", start: 54, offset: [29, 28, 27, 26, 4], vStep: -3 },
    { name: "5ths", start: 54, offset: [24, 28, 12, 16, 4], vStep: 5 },
    // b-griff bayan mirror
    { name: "N. Europe", start: 54, offset: [-1, 1, 3, 5, 4], vStep: 3 },
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
          if (track >= 0 && track < 4) { // track 0-3 = treble staff 4 voices
            showTreble = true
            var shiftedPitch = pitch - treble8veShift
            if (tempTreble.indexOf(shiftedPitch) === -1) {
              tempTreble.push(shiftedPitch)
            }
          } else if (track >= 4 && track < 8) { // bass staff 4 voices
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
                      // get chord from chord text marking above note(s)
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
      // automatic chord identification
      var activeStaffPitches = showTreble ? tempTreble : bassPitches
      if (activeStaffPitches.length === 0) {
        foundChordLbl.text = qsTr("none")
      } else if (activeStaffPitches.length < 3) {
        foundChordLbl.text = qsTr("select 3+ notes")
      } else {
        // make sorted copy
        var sortedPitches = activeStaffPitches.slice().sort(function(a, b) { return a - b })
        foundChordLbl.text = identifyChord(sortedPitches)
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
  } // timer end
  // highlight buttons for selected treble notes
  function mapTrebleNotes(row, col) {
    var base = selectedTrebleLayout.start
    var off = selectedTrebleLayout.offset[col]
    return (base + off) + (row * 3)
  }
  // highlight buttons for selected bass notes
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
  // color scheme of buttons & button text color
  function isBlackButton(pitch) {
    var p = pitch % 12
    return (p === 1 || p === 3 || p === 6 || p === 8 || p === 10)
  }
  // names of selected notes
  function getNoteName(pitch) {
    var names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    return names[pitch % 12]
  }
  // identify chord from selected notes
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
  // add staff text : identified chord
  function addChordText() {
    // console.log(qsTr("adding chord text to selected notes"))
    var chordFound = foundChordLbl.text
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
    // console.log("addChordText : firstNote=" + firstNote)
    // console.log("addChordText : firstNote.track=" + firstNote.track)

    curScore.startCmd()
    var textObj = newElement(Element.STAFF_TEXT)
    textObj.text = chordFound
    var cursor = curScore.newCursor()
    cursor.track = firstNote.track  // point auto-assigned track
    console.log("addChordText : cursor.track=" + cursor.track)
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
  // fingering text : add | toggle visibility | change fingering on double click
  function hideFinger() {
    if (!curScore || curScore.selection.elements.length === 0) {
      console.log("no score or nothing selected : exiting ...")
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
  // find if for selected notes a fingering text already exists
  function getExistingFinger(note) {
    for (var i = 0; i < note.elements.length; i++) {
      if (note.elements[i].type == Element.FINGERING) return note.elements[i]
    }
    return null
  }
  // collect notes data
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
  // calculate fingering for selected notes | get alternate fingering on double click
  // todo needsLove : better alternate finger selection logic
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
  } // functions end
  // user interface
  Window {
    id: mainWindow
    // added spaces at end to align text in title bar
    title: qsTr("poland chroma-button-accordion      ")
    flags: Qt.Window | Qt.WindowMinimizeButtonHint | Qt.WindowCloseButtonHint |
      Qt.WindowStaysOnTopHint // | Qt.WindowTitleHint | Qt.WindowSystemMenuHint
    width: 300
    height: showButtonboard ? expandedHeight : collapsedHeight
    x: showButtonboard ? 0 : 970 // dock left if showing buttonboard
    y: showButtonboard ? 124 : 0  // dock top if not showing buttonboard
    visible: true
    color: darkTheme
    // single column as main container : stack vertically
    Column {
      id: mainWidget
      width: parent.width
      height: parent.height
      anchors.fill: parent
      topPadding: 5
      Row { // fixed panel : chord identifier
        id: row1
        height: 32
        spacing: 6
        anchors.horizontalCenter: parent.horizontalCenter
        Label {
          id: foundChordLbl
          width: 250
          text: qsTr("none")
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          font.pixelSize: 22
          minimumPixelSize: 16
          color: "dodgerblue"
          // topPadding: 2
          fontSizeMode: Text.Fit
          ToolTip.text: qsTr("identify chord from selected notes - min 3" +
            "\ndouble-click any chord note to select chord" +
            "\ncan be added to selected notes")
          ToolTip.visible: showTooltips && chordLabelMArea.containsMouse 
          ToolTip.delay: tooltipDelay 
          MouseArea {
            id: chordLabelMArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton // allow click pass through
          }
        }
        // add identified chord as staff text
        Rectangle {
          id: addChordRect
          width: 26 
          height: 26 
          color: "transparent"
          ToolTip.text: qsTr("add identified chord to selected notes")
          ToolTip.visible: showTooltips && addChordMArea.containsMouse 
          ToolTip.delay: tooltipDelay 
          MouseArea {
            id: addChordMArea
            anchors.centerIn: parent
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // vector graphics
            Image {
              id: addChordImg
              anchors.fill: parent
              anchors.topMargin: 3
              source: addChordMArea.containsMouse ? Qt.resolvedUrl("imgs/addchordblue.png") :
                "imgs/addchordgray.png"
              smooth: true
              antialiasing: true
              fillMode: Image.PreserveAspectFit
            }
            // click handler
            onClicked: {
              addChordText()
              // console.log("added chord text")
            }
          }
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
          color: toggleBtnBrdMArea.containsMouse ? highlight1 : "#3c3c3c"
        }
        ToolTip.text: qsTr("toggle plugin position")
        ToolTip.visible: showTooltips && toggleBtnBrdMArea.containsMouse 
        ToolTip.delay: tooltipDelay 
        MouseArea {
          id: toggleBtnBrdMArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            showButtonboard = !showButtonboard
            // toggle buttonboard visibility by plugin height
            var targetHeight = showButtonboard ? expandedHeight : collapsedHeight
            cbaplugin.height = targetHeight
            mainWindow.height = targetHeight
          }
        }
      }
      // wrap row2 + ( row3 + row4 alternating) + buttonboard into container
      Column {
        id: buttonboard
        width: parent.width
        visible: showButtonboard
        spacing: 10
        // row2 
        Row { // checkboxes
          id: row2
          height: 32 
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 40
          topPadding: 4
          // use melodic / free bass for chord presentation
          Rectangle {
            id: meloBassRect
            width: iconSize 
            height: iconSize
            color: "transparent"
            ToolTip.text: qsTr("present as melodic / free bass" +
              "\nvs default stradella bass")
            ToolTip.visible: showTooltips && meloBassMArea.containsMouse 
            ToolTip.delay: tooltipDelay 
            MouseArea {
              id: meloBassMArea
              anchors.centerIn: parent
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              // vector graphics
              Image {
                id: meloBassImg
                anchors.fill: parent
                anchors.topMargin: 5
                source: meloBassMode ? Qt.resolvedUrl("imgs/melobassblue.png") :
                  (meloBassMArea.containsMouse ? "imgs/melobasswhite.png" :
                  "imgs/melobassgray.png")
                smooth: true
                antialiasing: true
                fillMode: Image.PreserveAspectFit
              }
              // click handler
              onClicked: {
                meloBassMode = !meloBassMode
                console.log("meloBassMode=", meloBassMode)
              }
            }
          }
          // show tone names on buttons
          Rectangle {
            id: buttonTonesRect
            width: iconSize 
            height: iconSize
            color: "transparent"
            ToolTip.text: qsTr("toggle button names")
            ToolTip.visible: showTooltips && buttonTonesMArea.containsMouse 
            ToolTip.delay: tooltipDelay 
            MouseArea {
              id: buttonTonesMArea
              anchors.centerIn: parent
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              // vector graphics
              Image {
                id: buttonTonesImg
                anchors.fill: parent
                anchors.topMargin: 5
                source: showButtonTones ? Qt.resolvedUrl("imgs/buttonnamesblue.png") :
                  (buttonTonesMArea.containsMouse ? "imgs/buttonnameswhite.png" :
                  "imgs/buttonnamesgray.png")
                smooth: true
                antialiasing: true
                fillMode: Image.PreserveAspectFit
              }
              // click handler
              onClicked: {
                showButtonTones = !showButtonTones
                console.log("showButtonTones=", showButtonTones)
              }
            }
          }
          // show fingering of selected notes : custom toggle icon
          Rectangle {
            id: fingerRect
            width: iconSize 
            height: iconSize
            color: "transparent"
            ToolTip.text: qsTr("add, hide or change fingering in treble part" +
              "\nselect whole measures" +
              "\ndouble-click to alternate fingering")
            ToolTip.visible: showTooltips && fingerMArea.containsMouse
            ToolTip.delay: tooltipDelay 
            MouseArea {
              id: fingerMArea
              anchors.centerIn: parent
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              // vector graphics
              Image {
                id: fingerImg
                anchors.fill: parent
                anchors.topMargin: 5
                source: showFingering ? Qt.resolvedUrl("imgs/fingerblue.png") :
                  (fingerMArea.containsMouse ? "imgs/fingerwhite.png" :
                  "imgs/fingergray.png")
                smooth: true
                antialiasing: true
                fillMode: Image.PreserveAspectFit
              }
              // click handler
              onClicked: {
                showFingering = !showFingering
                var currentTime = new Date().getTime()
                // detect double-click
                if (currentTime - lastClickTime < doubleClickSpeed) {
                  console.log("alternate fingering ...")
                  showFingering = true
                  calcFinger(true)
                } else {
                  if (showFingering) {
                    console.log("initial fingering ...")
                    calcFinger(false) // initial calculation
                  } else {
                    console.log("hiding fingering ...")
                    hideFinger()
                  }
                }
                lastClickTime = currentTime
              }
            }
          }
          // toggle tooltip visibility
          Rectangle {
            id: tooltipsRect 
            width: iconSize 
            height: iconSize
            color: "transparent"
            ToolTip.text: qsTr("toggle tooltips visibility" +
              "\nhover mouse over elements")
            ToolTip.visible: showTooltips && tooltipsMArea.containsMouse 
            ToolTip.delay: tooltipDelay 
            MouseArea {
              id: tooltipsMArea
              anchors.centerIn: parent
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              // vector graphics
              Image {
                id: tooltipsImg
                anchors.fill: parent
                anchors.topMargin: 5
                source: showTooltips ? Qt.resolvedUrl("imgs/helpblue.png") :
                  (tooltipsMArea.containsMouse ? "imgs/helpwhite.png" :
                  "imgs/helpgray.png")
                smooth: true
                antialiasing: true
                fillMode: Image.PreserveAspectFit
              }
              // click handler
              onClicked: {
                showTooltips = !showTooltips
                console.log("showTooltips=", showTooltips)
              }
            }
          }
        }
        // row 3 
        Row { // treble layout selection
          id: row3
          height: 25
          spacing: 12
          anchors.horizontalCenter: parent.horizontalCenter
          visible: showTreble
          ComboBox { // treble selector
            id: trebleSelector
            width: comboWidth
            ToolTip.text: qsTr("select treble layout")
            ToolTip.visible: showTooltips && hovered
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
            ToolTip.visible: showTooltips && hovered
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
          visible: !showTreble
          ComboBox { // bass selector
            id: bassSelector
            width: comboWidth 
            ToolTip.text: qsTr("select bass layout")
            ToolTip.visible: showTooltips && hovered
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
            ToolTip.visible: showTooltips && hovered
            ToolTip.delay: tooltipDelay 
            model: [24, 12, 0, -12, -24]
            onActivated: function(index) { bass8veShift = model[index] }
          }
        }
        Column { // buttonboards
          id: boardWidget
          width: parent.width
          topPadding: 7
          spacing: 20
          // treble board
          Item {
            id: trebleBrdItm
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
                      property int pitch: mapTrebleNotes(index, colIndex)
                      // determine button color
                      property bool black: isBlackButton(pitch)
                      color: isSelected ? highlight1 :
                      (black ? "#333333" : "#eeeeee")
                      border.color: "#777777"
                      border.width: 1
                      Text {
                        anchors.centerIn: parent
                        text: !black ? getNoteName(pitch) : ""
                        // only show names for naturals
                        visible: !black && showButtonTones
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
            id: bassBrdItm
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
                      color: isSelected ? highlight3 : (black ? "#333": "#eee")
                      border.color: "#555"
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

/* highlight potential colors
Green
DarkGreen
YellowGreen
OliveDrab
DarkOliveGreen
DarkSeaGreen */
