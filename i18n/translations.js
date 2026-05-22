// translations.js
var TRdictionary = {
  "title": {
    "en": "chromatic button accordion visual helper with chord identifier",
    "de": "visuelle hilfe für chromatisches knopfakkordeon mit akkord-identifikator",
    "fr": "assistant visuel pour accordéon chromatique à boutons avec identificateur d'accord",
    "es": "asistente visual de acordeón cromático de botones con identificador de acordes"
  },
  "unknown": {
    "en": "unknown",
    "de": "unbekannt",
    "fr": "inconnu",
    "es": "desconocido"
  },
  "select_notes_3plus": {
    "en": "select 3+ notes",
    "de": "3+ noten auswählen",
    "fr": "sélectionner 3+ notes",
    "es": "seleccionar 3+ notas"
  },
  "poland_layout": {
    "en": "poland chroma-button-accordion      ",
    "de": "poland chroma-knopf-akkordeon       ",
    "fr": "poland accordéon-chroma-boutons      ",
    "es": "poland acordeón-cromá-botones        "
  },
  "none": {
    "en": "none",
    "de": "keine",
    "fr": "aucun",
    "es": "ninguno"
  },
  "add_chord_to_notes": {
    "en": "add identified chord to selected notes",
    "de": "identifizierten akkord zu ausgewählten noten hinzufügen",
    "fr": "ajouter l'accord identifié aux notes sélectionnées",
    "es": "añadir el acorde identificado a las notas seleccionadas"
  },
  "identify_chord_tooltip": {
    "en": "identify chord from selected notes - min 3\ndouble-click any chord note to select chord\ncan be added to selected notes",
    "de": "akkord aus ausgewählten noten ermitteln - mind. 3\ndoppelklick auf eine akkordnote, um akkord auszuwählen\nkann zu ausgewählten noten hinzugefügt werden",
    "fr": "identifier l'accord des notes sélectionnées - min 3\ndouble-cliquer sur n'importe quelle note pour sélectionner l'accord\npeut être ajouté aux notes sélectionnées",
    "es": "identificar acorde de las notas seleccionadas - mín 3\ndoble clic en cualquier nota para seleccionar el acorde\nse puede añadir a las notas seleccionadas"
  },
  "toggle_position": {
    "en": "toggle plugin position",
    "de": "plugin-position umschalten",
    "fr": "basculer la position du plugin",
    "es": "alternar posición del complemento"
  },
  "present_free_bass": {
    "en": "present as melodic / free bass\nvs default stradella bass",
    "de": "als melodie-bass darstellen\nim vergleich zu standard-stradella-bass",
    "fr": "présenter comme basse libre\ncontre basse stradella par défaut",
    "es": "presentar como bajo libre\nfrente al bajo stradella predeterminado"
  },
  "toggle_button_names": {
    "en": "toggle button names",
    "de": "knopfnamen umschalten",
    "fr": "basculer le nom des boutons",
    "es": "alternar nombres de los botones"
  },
  "fingering_tooltip": {
    "en": "add, hide or change fingering in treble part\nselect whole measures\ndouble-click to alternate fingering",
    "de": "fingersatz im diskant hinzufügen, ausblenden oder ändern\nganze takte auswählen\ndoppelklick zum wechseln des fingersatzes",
    "fr": "ajouter, masquer ou modifier le doigté dans la partie chant\nsélectionner des mesures entières\ndouble-cliquer pour alterner le doigté",
    "es": "añadir, ocultar o cambiar la digitación en la parte del tiple\nseleccionar compases enteros\ndoble clic para alternar la digitación"
  },
  "toggle_tooltips": {
    "en": "toggle tooltips visibility\nhover mouse over elements",
    "de": "tooltips-sichtbarkeit umschalten\nmaus über elemente bewegen",
    "fr": "basculer la visibilité des infobulles\nsurvoler les éléments avec la souris",
    "es": "alternar visibilidad de los mensajes de ayuda\npasar el ratón sobre los elementos"
  },
  "select_treble_layout": {
    "en": "select treble layout",
    "de": "diskant-layout auswählen",
    "fr": "sélectionner la disposition du chant",
    "es": "seleccionar diseño del tiple"
  },
  "select_treble_8ve": {
    "en": "select treble 8ve\n0=3rd | -12=2nd | -24=1st",
    "de": "diskant-8ve auswählen\n0=3. | -12=2. | -24=1.",
    "fr": "sélectionner l'8ve du chant\n0=3e | -12=2e | -24=1re",
    "es": "seleccionar 8va del tiple\n0=3ª | -12=2ª | -24=1ª"
  },
  "select_bass_layout": {
    "en": "select bass layout",
    "de": "bass-layout auswählen",
    "fr": "sélectionner la disposition de la basse",
    "es": "seleccionar diseño del bajo"
  },
  "select_bass_8ve": {
    "en": "select bass 8ve\n24=5th | .. | 0=3rd | .. | -24=1st\nfor melodic / free bass only",
    "de": "bass-8ve auswählen\n24=5. | .. | 0=3. | .. | -24=1.\nnur für melodie-bass",
    "fr": "sélectionner l'8ve de la basse\n24=5e | .. | 0=3e | .. | -24=1re\npour basse libre uniquement",
    "es": "seleccionar 8va del bajo\n24=5ª | .. | 0=3ª | .. | -24=1ª\nsolo para bajo libre"
  }
}

function translate(key, lang) {
  if (TRdictionary[key]) {
    if (TRdictionary[key][lang]) {
      return TRdictionary[key][lang]
    }
    if (TRdictionary[key]["en"]) {
      return TRdictionary[key]["en"]
    }
  }
  return key
}
