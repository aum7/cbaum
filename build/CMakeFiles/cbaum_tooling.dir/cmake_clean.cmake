file(REMOVE_RECURSE
  "cbaum/cbaum.qml"
)

# Per-language clean rules from dependency scanning.
foreach(lang )
  include(CMakeFiles/cbaum_tooling.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
