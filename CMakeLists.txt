cmake_minimum_required(VERSION 3.16)
project(cbaum)
find_package(Qt6 COMPONENTS REQUIRED Core Qml Quick LinguistTools)
qt_standard_project_setup(I18N_TRANSLATED_LANGUAGES de fr es)
# add module
qt_add_qml_module(cbaum
  URI cbaum
  VERSION 1.0
  OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/cbaum
  QML_FILES
    cbaum.qml
)
# add translations
qt_add_translations(cbaum
  TS_FILES
    i18n/cbaum_de.ts
    i18n/cbaum_fr.ts
    i18n/cbaum_es.ts
)
