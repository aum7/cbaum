cmake_minimum_required(VERSION 3.16)
project(cbaum LANGUAGES CXX)
list(APPEND CMAKE_PREFIX_PATH "/usr/bin/cmake")
find_package(Qt6 6.4 REQUIRED COMPONENTS Core Qml Quick LinguistTools)
qt_standard_project_setup(REQUIRES 6.4)
# qt_standard_project_setup(REQUIRES 6.4 I18N_TRANSLATED_LANGUAGES de_DE fr_FR es_ES)
# add module
qt_add_qml_module(cbaum
  VERSION 1.0
  URI cbaum
  OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/cbaum
  QML_FILES
    cbaum.qml
)
# add translations
qt_add_translations(cbaum
  TS_FILE_BASE qml
  TS_FILE_DIR i18n
  LOCALES de_DE fr_FR es_ES
  RESOURCE_PREFIX /qt/qml/cbaum/i18n
)
